<?php

namespace App\Services;

use Illuminate\Http\Client\ConnectionException;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;
use UnexpectedValueException;

class BmkgForecastService
{
    private const string URL = 'https://api.bmkg.go.id/publik/prakiraan-cuaca';

    /** @return list<array{adm4:string, desa:string, kecamatan:string, kotkab:string, provinsi:string, sumber_kode:string}> */
    public function configuredAreas(): array
    {
        $areas = config('bmkg.weather_areas', []);
        if (! is_array($areas)) {
            return [];
        }

        $valid = [];
        foreach ($areas as $area) {
            if (! is_array($area)) {
                continue;
            }
            $adm4 = trim((string) ($area['adm4'] ?? ''));
            $desa = trim((string) ($area['desa'] ?? ''));
            $kecamatan = trim((string) ($area['kecamatan'] ?? ''));
            $kotkab = trim((string) ($area['kotkab'] ?? ''));
            $provinsi = trim((string) ($area['provinsi'] ?? ''));
            $source = trim((string) ($area['sumber_kode'] ?? ''));
            $verified = ($area['terverifikasi'] ?? false) === true;
            $officialBmkgPage = $this->isOfficialBmkgAreaPage($source, $adm4);
            $officialKemendagriReference = preg_match('/300\\.2\\.2-(?:2138|2430)/i', $source) === 1;
            if (! $verified
                || preg_match('/^13\.\d{2}\.\d{2}\.\d{4}$/', $adm4) !== 1
                || $desa === ''
                || $kecamatan === ''
                || $kotkab === ''
                || mb_strtolower($provinsi) !== 'sumatera barat'
                || (! $officialBmkgPage && ! $officialKemendagriReference)) {
                continue;
            }
            $valid[$adm4] = compact('adm4', 'desa', 'kecamatan', 'kotkab', 'provinsi') + [
                'sumber_kode' => $source,
            ];
        }

        return array_values(array_slice($valid, 0, 40, true));
    }

    /** @return array{updated:int,failed:int,skipped:bool} */
    public function synchronizeConfiguredAreas(): array
    {
        $areas = $this->configuredAreas();
        if ($areas === []) {
            Log::notice('BMKG forecast synchronization skipped; no verified ADM4 areas configured.');

            return ['updated' => 0, 'failed' => 0, 'skipped' => true];
        }

        $updated = 0;
        $failed = 0;
        foreach ($areas as $index => $area) {
            try {
                $forecast = $this->fetchAndNormalize($area);
                Cache::put(
                    $this->cacheKey($area['adm4']),
                    $forecast,
                    now()->addHours(max(1, (int) config('bmkg.forecast_cache_hours', 48))),
                );
                $updated++;
            } catch (\Throwable $exception) {
                $failed++;
                Log::warning('BMKG forecast area synchronization failed; prior cache retained.', [
                    'adm4' => $area['adm4'],
                    'failure_category' => $this->failureCategory($exception),
                    'exception_class' => $exception::class,
                ]);
            }

            // Keep a conservative margin below BMKG's documented 60 requests/minute/IP.
            if ($index < count($areas) - 1) {
                usleep(1_100_000);
            }
        }

        return ['updated' => $updated, 'failed' => $failed, 'skipped' => false];
    }

    /** @return array<string, mixed>|null */
    public function cachedForecast(string $adm4): ?array
    {
        if (! collect($this->configuredAreas())->contains('adm4', $adm4)) {
            return null;
        }
        $data = Cache::get($this->cacheKey($adm4));

        return is_array($data) ? $data : null;
    }

    /** @param array{adm4:string, desa:string, kecamatan:string, kotkab:string, provinsi:string, sumber_kode:string} $area
     * @return array<string, mixed>
     */
    private function fetchAndNormalize(array $area): array
    {
        $response = Http::timeout(12)
            ->acceptJson()
            ->get(self::URL, ['adm4' => $area['adm4']])
            ->throw();
        $payload = $response->json();
        if (! is_array($payload) || ! is_array($payload['lokasi'] ?? null)) {
            throw new UnexpectedValueException('BMKG forecast JSON has no location object.');
        }

        $location = $payload['lokasi'];
        $matches = ($location['adm4'] ?? null) === $area['adm4']
            && $this->sameName($location['provinsi'] ?? null, $area['provinsi'])
            && $this->sameName($location['kotkab'] ?? null, $area['kotkab'])
            && $this->sameName($location['kecamatan'] ?? null, $area['kecamatan'])
            && $this->sameName($location['desa'] ?? null, $area['desa']);
        if (! $matches) {
            throw new UnexpectedValueException('BMKG forecast location did not match the configured administrative record.');
        }

        $records = [];
        $analysisAt = null;
        foreach (($payload['data'] ?? []) as $day) {
            if (! is_array($day) || ! is_array($day['cuaca'] ?? null)) {
                continue;
            }
            foreach ($day['cuaca'] as $intervalGroup) {
                if (! is_array($intervalGroup)) {
                    continue;
                }
                foreach ($intervalGroup as $interval) {
                    if (! is_array($interval)) {
                        continue;
                    }
                    $description = trim((string) ($interval['weather_desc'] ?? ''));
                    $localDateTime = trim((string) ($interval['local_datetime'] ?? ''));
                    $utcDateTime = trim((string) ($interval['utc_datetime'] ?? ''));
                    if ($description === '' || $localDateTime === '' || $utcDateTime === '') {
                        continue;
                    }
                    try {
                        $local = \Illuminate\Support\Carbon::parse(
                            $localDateTime,
                            (string) config('bmkg.schedules.forecast_timezone', 'Asia/Jakarta'),
                        );
                        $utc = \Illuminate\Support\Carbon::parse($utcDateTime, 'UTC');
                    } catch (\Throwable) {
                        continue;
                    }
                    if ($local->lessThanOrEqualTo(now())) {
                        continue;
                    }
                    $analysisValue = $interval['analysis_date'] ?? null;
                    if (is_string($analysisValue) && trim($analysisValue) !== '') {
                        try {
                            $parsedAnalysis = \Illuminate\Support\Carbon::parse($analysisValue);
                            if ($analysisAt === null || $parsedAnalysis->greaterThan($analysisAt)) {
                                $analysisAt = $parsedAnalysis;
                            }
                        } catch (\Throwable) {
                            // Individual source timestamp is optional, but never invent one.
                        }
                    }
                    $records[] = [
                        'waktu_lokal' => $local->toIso8601String(),
                        'waktu_utc' => $utc->toIso8601String(),
                        'kondisi' => $description,
                        'suhu_c' => is_numeric($interval['t'] ?? null) ? (float) $interval['t'] : null,
                        'kelembapan_persen' => is_numeric($interval['hu'] ?? null) ? (int) $interval['hu'] : null,
                        'kecepatan_angin_kmh' => is_numeric($interval['ws'] ?? null) ? (float) $interval['ws'] : null,
                    ];
                }
            }
        }
        if ($records === []) {
            throw new UnexpectedValueException('BMKG forecast contains no valid future intervals.');
        }
        usort($records, static fn (array $a, array $b): int => strcmp($a['waktu_utc'], $b['waktu_utc']));

        return [
            'wilayah' => $area,
            'prakiraan' => $records,
            'waktu_data_dibuat' => $analysisAt?->toIso8601String(),
            'waktu_diambil' => now()->toIso8601String(),
            'sumber' => 'BMKG',
            'url_sumber' => self::URL.'?adm4='.rawurlencode($area['adm4']),
        ];
    }

    private function sameName(mixed $actual, string $expected): bool
    {
        return is_string($actual)
            && mb_strtolower(preg_replace('/\s+/', ' ', trim($actual)) ?? '')
                === mb_strtolower(preg_replace('/\s+/', ' ', trim($expected)) ?? '');
    }

    private function isOfficialBmkgAreaPage(string $source, string $adm4): bool
    {
        $parts = parse_url($source);

        return is_array($parts)
            && ($parts['scheme'] ?? '') === 'https'
            && ($parts['host'] ?? '') === 'www.bmkg.go.id'
            && ($parts['path'] ?? '') === '/cuaca/prakiraan-cuaca/'.$adm4;
    }

    private function cacheKey(string $adm4): string
    {
        return 'bmkg_forecast_'.str_replace('.', '_', $adm4);
    }

    private function failureCategory(\Throwable $exception): string
    {
        return match (true) {
            $exception instanceof \Illuminate\Http\Client\RequestException => 'http_status_failure',
            $exception instanceof ConnectionException && preg_match('/timed?\s*out|timeout/i', $exception->getMessage()) === 1 => 'timeout',
            $exception instanceof ConnectionException => 'connection_failure',
            $exception instanceof UnexpectedValueException => 'feed_parse_or_validation',
            default => 'unexpected_failure',
        };
    }
}
