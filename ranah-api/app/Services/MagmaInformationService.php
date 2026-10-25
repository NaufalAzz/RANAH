<?php

namespace App\Services;

use App\Models\Gunung;
use App\Models\Berita;
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
        $previousStatuses = [];
        foreach ($activity as $row) {
            $existing = $this->findByNameAndProvince($row['name'], $row['province']);
            $key = $this->volcanoKey($row['name'], $row['province']);
            $previousStatuses[$key] = $existing?->status_aktivitas;
        }

        DB::transaction(function () use ($activity, $fetchedAt, $previousStatuses): void {
            foreach ($activity as $row) {
                $gunung = $this->findByNameAndProvince($row['name'], $row['province']);
                $previousStatus = trim((string) ($previousStatuses[$this->volcanoKey($row['name'], $row['province'])] ?? ''));
                $statusChanged = $this->isKnownActivityStatus($previousStatus)
                    && $previousStatus !== $row['status'];
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

                if ($statusChanged && $gunung !== null) {
                    Berita::query()->updateOrCreate(
                        ['sumber_id' => $this->statusChangeSourceId($row['report_id'], $previousStatus, $row['status'])],
                        [
                            'judul' => 'Perubahan tingkat aktivitas '.$gunung->nama,
                            'kategori' => 'Aktivitas gunung api',
                            'jenis_konten' => 'kejadian',
                            'isi' => 'Daftar aktivitas MAGMA berubah dari '.$previousStatus.' menjadi '.$row['status'].'. Periksa tautan laporan sumber untuk rincian dan rekomendasi.',
                            'gambar' => null,
                            'sumber' => self::SOURCE,
                            'url_sumber' => $row['report_url'],
                            'wilayah' => $gunung->provinsi,
                            // The listing provides no publication/event time; retain that uncertainty.
                            'waktu_publikasi' => null,
                            'waktu_kejadian' => null,
                            'waktu_berakhir' => null,
                            'waktu_pengambilan' => $fetchedAt,
                            'status_publikasi' => 'published',
                        ],
                    );
                }
            }
        });

        if ($reportFor !== null && trim($reportFor) !== '') {
            $selected = $this->findActivityRow($activity, $reportFor);
            $previousStatus = $selected === null
                ? null
                : ($previousStatuses[$this->volcanoKey($selected['name'], $selected['province'])] ?? null);
            $this->synchronizeReportFromActivity($activity, $reportFor, $previousStatus);
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
    private function synchronizeReportFromActivity(
        array $activity,
        string $volcanoName,
        ?string $previousStatusOverride = null,
    ): int
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

        DB::transaction(function () use ($selected, $detail, $date, $fetchedAt, $previousStatusOverride): void {
            $gunung = $this->findByNameAndProvince($selected['name'], $selected['province']);
            if ($gunung === null) {
                throw new RuntimeException('The selected volcano must first be synchronized from the MAGMA listing.');
            }
            $previousStatus = trim((string) ($previousStatusOverride ?? $gunung->status_aktivitas));
            $statusChanged = $this->isKnownActivityStatus($previousStatus)
                && $previousStatus !== $detail['status'];
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

            if ($statusChanged && $previousStatusOverride === null) {
                Berita::query()->updateOrCreate(
                    ['sumber_id' => $this->statusChangeSourceId($selected['report_id'], $previousStatus, $detail['status'])],
                    [
                        'judul' => 'Pembaruan tingkat aktivitas '.$gunung->nama,
                        'kategori' => 'Aktivitas gunung api',
                        'jenis_konten' => 'kejadian',
                        'isi' => 'Laporan MAGMA mencatat perubahan status dari '.$previousStatus.' menjadi '.$detail['status'].'. Rekomendasi dan pengamatan terbaru tersedia pada laporan sumber.',
                        'gambar' => null,
                        'sumber' => self::SOURCE,
                        'url_sumber' => $selected['report_url'],
                        'wilayah' => $gunung->provinsi,
                        'waktu_publikasi' => $date->startOfDay(),
                        'waktu_kejadian' => $date->startOfDay(),
                        'waktu_berakhir' => null,
                        'waktu_pengambilan' => $fetchedAt,
                        'status_publikasi' => 'published',
                    ],
                );
            }
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

    private function volcanoKey(string $name, string $province): string
    {
        return $this->normalizeName($name).'|'.mb_strtolower(trim($province));
    }

    private function statusChangeSourceId(string $reportId, string $previousStatus, string $currentStatus): string
    {
        return 'magma-status:'.hash('sha256', $reportId.'|'.$previousStatus.'|'.$currentStatus);
    }

    private function isKnownActivityStatus(string $status): bool
    {
        return preg_match('/^Level\s+(?:I|II|III|IV)\b/i', trim($status)) === 1;
    }

    /** @param list<array{name:string,province:string,status:string,report_id:string,report_url:string}> $activity
     * @return array{name:string,province:string,status:string,report_id:string,report_url:string}|null
     */
    private function findActivityRow(array $activity, string $volcanoName): ?array
    {
        foreach ($activity as $row) {
            if ($this->normalizeName($row['name']) === $this->normalizeName($volcanoName)) {
                return $row;
            }
        }

        return null;
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
