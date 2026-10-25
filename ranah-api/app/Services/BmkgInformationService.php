<?php

namespace App\Services;

use App\Models\Berita;
use Carbon\CarbonImmutable;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;
use JsonException;
use SimpleXMLElement;
use UnexpectedValueException;

class BmkgInformationService
{
    private const string FELT_QUAKES_URL = 'https://data.bmkg.go.id/DataMKG/TEWS/gempadirasakan.json';

    private const string LATEST_QUAKE_URL = 'https://data.bmkg.go.id/DataMKG/TEWS/autogempa.json';

    private const string LATEST_M5_QUAKES_URL = 'https://data.bmkg.go.id/DataMKG/TEWS/gempaterkini.json';

    private const string WEATHER_ALERTS_URL = 'https://www.bmkg.go.id/alerts/nowcast/id';

    public function synchronizeFeltEarthquakes(): int
    {
        $feltPayload = $this->fetchJson(self::FELT_QUAKES_URL, 'felt_earthquakes');
        $latestPayload = $this->fetchJson(self::LATEST_QUAKE_URL, 'latest_earthquake');
        $latestM5Payload = $this->fetchJson(self::LATEST_M5_QUAKES_URL, 'latest_m5_earthquakes');

        if (! is_array($feltPayload['Infogempa']['gempa'] ?? null)
            || ! is_array($latestPayload['Infogempa']['gempa'] ?? null)
            || ! is_array($latestM5Payload['Infogempa']['gempa'] ?? null)) {
            throw $this->invalidFeed('earthquakes', 'json_structure', 'unexpected_root_structure');
        }

        $normalizedBySourceId = [];
        $outOfScope = 0;
        $invalidRecords = 0;
        $considerEarthquake = function (mixed $earthquake, string $sourceUrl) use (&$normalizedBySourceId, &$outOfScope, &$invalidRecords): void {
            if (! is_array($earthquake)) {
                $invalidRecords++;

                return;
            }
            $feltAreas = trim((string) ($earthquake['Dirasakan'] ?? ''));
            $epicenterArea = trim((string) ($earthquake['Wilayah'] ?? ''));
            if (! $this->hasWestSumatraLocality($feltAreas.' '.$epicenterArea)) {
                $outOfScope++;

                return;
            }
            $normalized = $this->normalizeEarthquake($earthquake, $sourceUrl);
            if ($normalized === null) {
                $invalidRecords++;

                return;
            }
            $normalizedBySourceId[$normalized['sumber_id']] = $normalized;
        };

        foreach ($feltPayload['Infogempa']['gempa'] as $earthquake) {
            $considerEarthquake($earthquake, self::FELT_QUAKES_URL);
        }
        $considerEarthquake($latestPayload['Infogempa']['gempa'], self::LATEST_QUAKE_URL);
        foreach ($latestM5Payload['Infogempa']['gempa'] as $earthquake) {
            $considerEarthquake($earthquake, self::LATEST_M5_QUAKES_URL);
        }

        Log::info('BMKG earthquake feed processed', [
            'feed' => 'earthquakes',
            'records_received' => count($feltPayload['Infogempa']['gempa']) + 1 + count($latestM5Payload['Infogempa']['gempa']),
            'records_out_of_sumbar_scope' => $outOfScope,
            'records_invalid' => $invalidRecords,
            'records_matching_sumbar' => count($normalizedBySourceId),
            'result' => $normalizedBySourceId === [] ? 'valid_feed_no_sumbar_matches' : 'valid_feed_matches_found',
        ]);

        if ($invalidRecords > 0) {
            Log::warning('BMKG earthquake feed contained invalid records', [
                'feed' => 'earthquakes',
                'records_invalid' => $invalidRecords,
            ]);
            throw $this->invalidFeed('earthquakes', 'record_validation', 'invalid_sumbar_records');
        }

        $count = DB::transaction(function () use ($normalizedBySourceId): int {
            foreach ($normalizedBySourceId as $attributes) {
                Berita::query()->updateOrCreate(['sumber_id' => $attributes['sumber_id']], $attributes);
            }

            return count($normalizedBySourceId);
        });
        Cache::put('bmkg_earthquake_last_success_at', now()->toIso8601String(), now()->addDays(30));

        return $count;
    }

    public function synchronizeWestSumatraWeatherAlerts(): int
    {
        $response = Http::timeout(10)
            ->accept('application/rss+xml, application/xml, text/xml')
            ->get(self::WEATHER_ALERTS_URL)
            ->throw();
        $feed = $this->parseXml($response->body());
        $channels = $feed->xpath('/*[local-name()="rss"]/*[local-name()="channel"]');
        if ($channels === false || $channels === []) {
            throw $this->invalidFeed('weather_alerts', 'rss_validation', 'missing_rss_channel');
        }
        $feedItems = $channels[0]->xpath('./*[local-name()="item"]');
        if ($feedItems === false) {
            throw $this->invalidFeed('weather_alerts', 'rss_validation', 'unreadable_rss_items');
        }

        $normalizedBySourceId = [];
        $sumatraCandidates = 0;
        $excludedRecords = 0;
        foreach ($feedItems as $feedItem) {
            $title = $this->xmlValue($feedItem, 'title');
            $description = $this->xmlValue($feedItem, 'description');
            if (! $this->mentionsWestSumatra($title.' '.$description)) {
                continue;
            }
            $sumatraCandidates++;
            $detailUrl = $this->validatedCapUrl($this->xmlValue($feedItem, 'link'));
            $detailResponse = Http::timeout(10)
                ->accept('application/xml, text/xml')
                ->get($detailUrl)
                ->throw();
            $publishedAt = $this->parseDate($this->xmlValue($feedItem, 'pubDate'));
            if ($publishedAt === null) {
                throw $this->invalidFeed('weather_alerts', 'rss_validation', 'invalid_publication_date');
            }
            $normalized = $this->normalizeWeatherAlert(
                $this->parseXml($detailResponse->body()),
                $detailUrl,
                $publishedAt,
            );
            if ($normalized !== null) {
                $normalizedBySourceId[$normalized['sumber_id']] = $normalized;
            } else {
                $excludedRecords++;
            }
        }

        Log::info('BMKG weather alert feed processed', [
            'feed' => 'weather_alerts',
            'records_received' => count($feedItems),
            'west_sumatra_candidates' => $sumatraCandidates,
            'records_excluded_by_sumbar_or_expiry_filter' => $excludedRecords,
            'active_sumbar_alerts' => count($normalizedBySourceId),
            'result' => $normalizedBySourceId === [] ? 'valid_feed_no_active_sumbar_alerts' : 'valid_feed_active_alerts_found',
        ]);

        $count = DB::transaction(function () use ($normalizedBySourceId): int {
            $activeSourceIds = array_keys($normalizedBySourceId);
            // A successfully parsed feed is the current active listing. Preserve
            // prior records, but stop presenting omitted alerts as active.
            Berita::query()->where('sumber_id', 'like', 'bmkg-cap:%')
                ->where('status_publikasi', 'published')
                ->get()
                ->each(function (Berita $item) use ($activeSourceIds): void {
                    if ($this->hasWestSumatraLocality((string) $item->wilayah)
                        && ! in_array((string) $item->sumber_id, $activeSourceIds, true)) {
                        $item->update(['status_publikasi' => 'archived']);
                    }
                });
            foreach ($normalizedBySourceId as $attributes) {
                Berita::query()->updateOrCreate(['sumber_id' => $attributes['sumber_id']], $attributes);
            }

            return count($normalizedBySourceId);
        });
        Cache::put('bmkg_weather_last_success_at', now()->toIso8601String(), now()->addDays(30));

        return $count;
    }

    /** @param array<string, mixed> $earthquake
     * @return array<string, mixed>|null
     */
    private function normalizeEarthquake(array $earthquake, string $sourceUrl): ?array
    {
        $feltAreas = trim((string) ($earthquake['Dirasakan'] ?? ''));
        $epicenterArea = trim((string) ($earthquake['Wilayah'] ?? ''));
        $dateTime = $this->parseDate($earthquake['DateTime'] ?? null);
        $coordinates = trim((string) ($earthquake['Coordinates'] ?? ''));
        $magnitude = trim((string) ($earthquake['Magnitude'] ?? ''));
        if ($dateTime === null
            || preg_match('/^-?\d+(?:\.\d+)?,-?\d+(?:\.\d+)?$/', $coordinates) !== 1
            || ! is_numeric($magnitude)) {
            return null;
        }
        [$latitude, $longitude] = array_map('floatval', explode(',', $coordinates));
        if ($latitude < -90 || $latitude > 90 || $longitude < -180 || $longitude > 180) {
            return null;
        }

        $sourceId = 'bmkg-quake:'.hash('sha256', $dateTime->toIso8601String().'|'.$coordinates);
        $potential = trim((string) ($earthquake['Potensi'] ?? ''));
        $isTsunamiPotential = preg_match('/\b(?:tidak|nihil)\s+berpotensi\s+tsunami\b/i', $potential) !== 1
            && preg_match('/\bberpotensi\s+tsunami\b/i', $potential) === 1;
        $category = $isTsunamiPotential ? 'Tsunami' : 'Gempa';
        $body = 'Data kejadian BMKG mencatat gempa bermagnitudo M'.number_format((float) $magnitude, 1, '.', '').'.';
        foreach (['Kedalaman' => 'Kedalaman', 'Wilayah' => 'Keterangan lokasi episenter'] as $field => $label) {
            $value = trim((string) ($earthquake[$field] ?? ''));
            if ($value !== '') {
                $body .= ' '.$label.' menurut BMKG: '.$value.'.';
            }
        }
        if ($feltAreas !== '') {
            $body .= ' Wilayah yang dinyatakan merasakan: '.$feltAreas.'.';
        }
        if ($potential !== '') {
            $body .= ' Potensi menurut data BMKG: '.$potential.'.';
        }
        $body .= ' Ini adalah laporan kejadian, bukan peringatan aktif.';

        return [
            'judul' => $isTsunamiPotential
                ? 'Laporan gempa BMKG relevan dengan Sumatera Barat dengan potensi tsunami'
                : 'Informasi gempa BMKG relevan dengan Sumatera Barat',
            'kategori' => $category,
            'jenis_konten' => 'kejadian',
            'isi' => $body,
            'gambar' => null,
            'sumber' => 'BMKG',
            'sumber_id' => $sourceId,
            'url_sumber' => $sourceUrl,
            'wilayah' => trim(implode('; ', array_filter([
                $feltAreas === '' ? null : 'Dirasakan: '.$feltAreas,
                $epicenterArea === '' ? null : 'Episenter: '.$epicenterArea,
            ]))),
            'waktu_publikasi' => null,
            'waktu_kejadian' => $dateTime,
            'waktu_berakhir' => null,
            'waktu_pengambilan' => now(),
            'status_publikasi' => 'published',
        ];
    }

    public function hasWestSumatraLocality(string $regions): bool
    {
        foreach (config('bmkg.sumatera_barat.localities', []) as $locality) {
            if (preg_match('/(?<![\pL\pN])'.preg_quote($locality, '/').'(?![\pL\pN])/iu', $regions) === 1) {
                return true;
            }
        }

        if (preg_match('/(?<![\pL\pN])(?:Kota\s+)?Padang(?=$|[,;:\s-])(?!\s+(?:Lawas|Sidempuan|Sidimpuan))/iu', $regions) === 1) {
            return true;
        }

        return preg_match(
            '/(?:^|[,;]\s*)(?:(?:[IVX]+(?:\s*[-–]\s*[IVX]+)?|[0-9]+(?:\s*-\s*[0-9]+)?)\s+)?(?:(?:Kota|Kecamatan|Kec\.)\s+)?Padang(?:\s*(?:[,;]|$)|\s+(?:Barat|Timur|Selatan|Utara)\s*(?:[,;]|$))/iu',
            $regions,
        ) === 1;
    }

    private function mentionsWestSumatra(string $value): bool
    {
        return preg_match('/\b(?:Sumatera\s+Barat|Sumbar)\b/iu', $value) === 1;
    }

    private function validatedCapUrl(string $value): string
    {
        $url = trim($value);
        $parts = filter_var($url, FILTER_VALIDATE_URL) ? parse_url($url) : false;
        if (! is_array($parts)
            || ($parts['scheme'] ?? '') !== 'https'
            || ($parts['host'] ?? '') !== 'www.bmkg.go.id'
            || ! str_starts_with((string) ($parts['path'] ?? ''), '/alerts/nowcast/id/')) {
            throw $this->invalidFeed('weather_alerts', 'url_validation', 'untrusted_cap_url');
        }

        return $url;
    }

    private function normalizeWeatherAlert(
        SimpleXMLElement $alert,
        string $sourceUrl,
        CarbonImmutable $publishedAt,
    ): ?array {
        $identifier = $this->xmlValue($alert, 'identifier');
        $informationNodes = $alert->xpath('//*[local-name()="info"]');
        if ($identifier === '' || $informationNodes === false || $informationNodes === []) {
            throw $this->invalidFeed('weather_alerts', 'cap_validation', 'missing_identifier_or_info');
        }
        $information = $informationNodes[0];
        $headline = $this->xmlValue($information, 'headline');
        $event = $this->xmlValue($information, 'event');
        $description = $this->xmlValue($information, 'description');
        $severity = $this->xmlValue($information, 'severity');
        $effective = $this->parseDate($this->xmlValue($information, 'effective'));
        $expires = $this->parseDate($this->xmlValue($information, 'expires'));
        $areaNodes = $information->xpath('.//*[local-name()="areaDesc"]');
        $areas = $areaNodes === false ? [] : array_values(array_filter(array_map(
            static fn (SimpleXMLElement $area): string => trim((string) $area),
            $areaNodes,
        )));
        $region = implode('; ', $areas);
        if ($headline === '' || $description === '' || $effective === null || $expires === null || $region === '') {
            throw $this->invalidFeed('weather_alerts', 'cap_validation', 'missing_required_fields');
        }
        if ($expires->lessThanOrEqualTo(now()) || ! $this->hasWestSumatraLocality($region)) {
            return null;
        }

        return [
            'judul' => $headline,
            'kategori' => 'Imbauan/penanganan bencana',
            'jenis_konten' => 'peringatan',
            'isi' => ($event === '' ? '' : $event.'. ').$description,
            'gambar' => null,
            'sumber' => 'BMKG',
            'sumber_id' => 'bmkg-cap:'.hash('sha256', $identifier),
            'tingkat_kepentingan' => in_array($severity, ['Extreme', 'Severe', 'Moderate', 'Minor', 'Unknown'], true)
                ? $severity
                : null,
            'url_sumber' => $sourceUrl,
            'wilayah' => $region,
            'waktu_publikasi' => $publishedAt,
            'waktu_kejadian' => $effective,
            'waktu_berakhir' => $expires,
            'waktu_pengambilan' => now(),
            'status_publikasi' => 'published',
        ];
    }

    private function parseXml(string $content): SimpleXMLElement
    {
        $previousErrorMode = libxml_use_internal_errors(true);
        try {
            $parsed = simplexml_load_string(
                $content,
                SimpleXMLElement::class,
                LIBXML_NONET | LIBXML_NOCDATA | LIBXML_NOBLANKS,
            );
        } finally {
            libxml_clear_errors();
            libxml_use_internal_errors($previousErrorMode);
        }
        if (! $parsed instanceof SimpleXMLElement) {
            throw $this->invalidFeed('weather_alerts', 'xml_parse', 'invalid_xml');
        }

        return $parsed;
    }

    private function xmlValue(SimpleXMLElement $element, string $name): string
    {
        $matches = $element->xpath('.//*[local-name()="'.$name.'"]');

        return $matches === false || $matches === [] ? '' : trim((string) $matches[0]);
    }

    private function parseDate(mixed $value): ?CarbonImmutable
    {
        if (! is_string($value) || trim($value) === '') {
            return null;
        }
        try {
            return CarbonImmutable::parse($value);
        } catch (\Throwable) {
            return null;
        }
    }

    /** @return array<string, mixed> */
    private function fetchJson(string $url, string $feed): array
    {
        $response = Http::timeout(10)->acceptJson()->get($url)->throw();
        try {
            $payload = json_decode($response->body(), true, 512, JSON_THROW_ON_ERROR);
        } catch (JsonException) {
            throw $this->invalidFeed($feed, 'json_parse', 'invalid_json');
        }
        if (! is_array($payload)) {
            throw $this->invalidFeed($feed, 'json_parse', 'unexpected_json_value');
        }

        return $payload;
    }

    private function invalidFeed(string $feed, string $stage, string $reason): UnexpectedValueException
    {
        Log::warning('BMKG source response failed validation', [
            'feed' => $feed,
            'stage' => $stage,
            'reason' => $reason,
        ]);

        return new UnexpectedValueException("BMKG {$feed} response failed {$stage} validation ({$reason}).");
    }
}
