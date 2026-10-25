<?php

namespace App\Services;

use App\Models\Gunung;
use App\Models\LaporanGunung;
use Carbon\CarbonImmutable;
use Illuminate\Http\Client\RequestException;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Http;
use RuntimeException;

class MagmaInformationService
{
    private const ACTIVITY_URL = 'https://magma.esdm.go.id/v1/gunung-api/tingkat-aktivitas';

    private const SOURCE = 'MAGMA Indonesia';

    public function __construct(private readonly MagmaHtmlParser $parser) {}

    /** Synchronizes the current listing only; it never removes records absent from MAGMA. */
    public function synchronizeActivityListing(?string $reportFor = null): int
    {
        $activityHtml = $this->fetch(self::ACTIVITY_URL);
        $activity = $this->parser->parseActivityListing($activityHtml);
        if ($activity === []) {
            throw new RuntimeException('MAGMA activity listing did not contain usable volcano records.');
        }

        $fetchedAt = now();
        DB::transaction(function () use ($activity, $fetchedAt): void {
            foreach ($activity as $row) {
                $gunung = $this->findByNameAndProvince($row['name'], $row['province']);
                $attributes = [
                    'nama' => $row['name'],
                    'provinsi' => $row['province'],
                    'status_aktivitas' => $row['status'],
                    'sumber_data' => self::SOURCE,
                    'waktu_pengambilan' => $fetchedAt,
                    // The listing membership is not a volcano active/inactive classification.
                    'aktif' => true,
                ];
                if ($gunung === null) {
                    Gunung::query()->create($attributes);
                } else {
                    $gunung->fill($attributes)->save();
                }
            }
        });

        if ($reportFor !== null && trim($reportFor) !== '') {
            $this->synchronizeReportFromActivity($activity, $reportFor);
        }

        return count($activity);
    }

    /** Fetches at most one exact signed detail URL selected from MAGMA's public listing. */
    public function synchronizeOneReport(string $volcanoName): int
    {
        $activityHtml = $this->fetch(self::ACTIVITY_URL);
        $activity = $this->parser->parseActivityListing($activityHtml);

        return $this->synchronizeReportFromActivity($activity, $volcanoName);
    }

    /** @param list<array{name:string,province:string,status:string,report_id:string,report_url:string}> $activity */
    private function synchronizeReportFromActivity(array $activity, string $volcanoName): int
    {
        $selected = null;
        foreach ($activity as $row) {
            if ($this->normalizeName($row['name']) === $this->normalizeName($volcanoName)) {
                $selected = $row;
                break;
            }
        }
        if ($selected === null || $this->parser->signedReportUrl($selected['report_url']) === null) {
            throw new RuntimeException('No valid signed MAGMA report link was found for the requested volcano.');
        }
        $detail = $this->parser->parseReportDetail($this->fetch($selected['report_url']));
        if ($this->normalizeName($detail['name']) !== $this->normalizeName($selected['name'])) {
            throw new RuntimeException('MAGMA detail name does not match the selected activity listing.');
        }
        $date = $this->parseIndonesianDate($detail['period_date']);
        $fetchedAt = now();

        DB::transaction(function () use ($selected, $detail, $date, $fetchedAt): void {
            $gunung = $this->findByNameAndProvince($selected['name'], $selected['province']);
            if ($gunung === null) {
                throw new RuntimeException('The selected volcano must first be synchronized from the MAGMA listing.');
            }
            $attributes = [
                'status_aktivitas' => $detail['status'],
                'sumber_data' => self::SOURCE,
                'waktu_pengambilan' => $fetchedAt,
            ];
            if ($gunung->status_validasi_koordinat !== 'terverifikasi') {
                $attributes['latitude'] = $detail['latitude'] ?? $gunung->latitude;
                $attributes['longitude'] = $detail['longitude'] ?? $gunung->longitude;
            }
            $gunung->fill($attributes)->save();

            LaporanGunung::query()->updateOrCreate(
                ['sumber' => self::SOURCE, 'sumber_id' => $selected['report_id']],
                [
                    'gunung_id' => $gunung->id,
                    'periode_mulai' => $date->toDateString(),
                    'periode_selesai' => $date->toDateString(),
                    'periode_waktu' => $detail['period_time'],
                    'data_klimatologi' => $detail['climate'],
                    'pengamatan_visual' => $detail['observation'],
                    'rekomendasi' => $detail['recommendation'],
                    'url_sumber' => $selected['report_url'],
                    'waktu_publikasi' => $date->startOfDay(),
                    'waktu_pengambilan' => $fetchedAt,
                ],
            );
        });

        return 1;
    }

    private function fetch(string $url): string
    {
        $response = Http::accept('text/html')->connectTimeout(8)->timeout(20)->get($url);
        if ($response->status() === 429) {
            throw new RequestException($response);
        }
        $response->throw();
        if (! str_contains(strtolower((string) $response->header('Content-Type')), 'text/html') || trim($response->body()) === '') {
            throw new RuntimeException('MAGMA returned an empty or non-HTML response.');
        }

        return $response->body();
    }

    private function normalizeName(string $name): string
    {
        $name = preg_replace('/^Gunung\s+/iu', '', trim($name)) ?? trim($name);

        return mb_strtolower(preg_replace('/[^\pL\pN]+/u', '', $name) ?? $name);
    }

    private function findByNameAndProvince(string $name, string $province): ?Gunung
    {
        $matches = Gunung::query()->get()
            ->filter(fn (Gunung $candidate): bool => $this->normalizeName($candidate->nama) === $this->normalizeName($name));
        $sameRegion = $matches->filter(
            fn (Gunung $candidate): bool => mb_strtolower(trim($candidate->provinsi)) === mb_strtolower(trim($province)),
        );

        if ($sameRegion->count() === 1) {
            return $sameRegion->first();
        }
        if ($sameRegion->count() > 1 || $matches->count() > 1) {
            throw new RuntimeException('MAGMA volcano name matches multiple existing database records.');
        }

        return $matches->first();
    }

    private function parseIndonesianDate(string $value): CarbonImmutable
    {
        $months = ['januari' => 1, 'februari' => 2, 'maret' => 3, 'april' => 4, 'mei' => 5, 'juni' => 6, 'juli' => 7, 'agustus' => 8, 'september' => 9, 'oktober' => 10, 'november' => 11, 'desember' => 12];
        if (! preg_match('/^(\d{1,2})\s+(\pL+)\s+(\d{4})$/iu', trim($value), $match)
            || ! isset($months[mb_strtolower($match[2])])) {
            throw new RuntimeException('MAGMA publication date is invalid.');
        }

        return CarbonImmutable::create((int) $match[3], $months[mb_strtolower($match[2])], (int) $match[1], 0, 0, 0);
    }
}
