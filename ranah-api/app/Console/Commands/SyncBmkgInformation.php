<?php

namespace App\Console\Commands;

use App\Services\BmkgForecastService;
use App\Services\BmkgInformationService;
use App\Services\BmkgSyncStatus;
use Illuminate\Console\Attributes\Description;
use Illuminate\Console\Attributes\Signature;
use Illuminate\Console\Command;
use Illuminate\Http\Client\ConnectionException;
use Illuminate\Http\Client\RequestException;
use Illuminate\Support\Facades\Log;
use Throwable;

#[Signature('ranah:sync-bmkg {--feed=all : all, earthquakes, weather-alerts, or forecasts}')]
#[Description('Sinkronkan kejadian gempa, prakiraan, dan peringatan dini cuaca resmi BMKG.')]
class SyncBmkgInformation extends Command
{
    public function handle(
        BmkgInformationService $service,
        BmkgForecastService $forecasts,
        BmkgSyncStatus $statuses,
    ): int {
        $tasks = [
            'earthquakes' => fn (): int => $service->synchronizeFeltEarthquakes(),
            'weather-alerts' => fn (): int => $service->synchronizeWestSumatraWeatherAlerts(),
            'forecasts' => fn (): array => $forecasts->synchronizeConfiguredAreas(),
        ];
        $selected = (string) $this->option('feed');
        if ($selected !== 'all' && ! array_key_exists($selected, $tasks)) {
            $this->error('Nilai --feed harus all, earthquakes, weather-alerts, atau forecasts.');

            return self::INVALID;
        }

        $hasFailures = false;
        foreach ($tasks as $feed => $task) {
            if ($selected !== 'all' && $selected !== $feed) {
                continue;
            }
            $statusKey = match ($feed) {
                'weather-alerts' => 'weather_alerts',
                'forecasts' => 'forecasts',
                default => 'earthquakes',
            };
            $statuses->attempted($statusKey);

            try {
                $result = $task();
                if ($feed === 'forecasts') {
                    if ($result['skipped']) {
                        $statuses->unavailable($statusKey, 'wilayah_belum_dikonfigurasi');
                        $this->warn('Prakiraan BMKG belum diperiksa: belum ada kode wilayah ADM4 Sumatera Barat yang tervalidasi dan dikonfigurasi.');

                        continue;
                    }
                    if ($result['failed'] > 0) {
                        if ($result['updated'] > 0) {
                            $statuses->partial($statusKey, $result['updated'], $result['failed']);
                        } else {
                            $statuses->failed($statusKey, 'all_configured_areas_failed');
                        }
                        $hasFailures = true;
                        $this->warn("Sinkronisasi prakiraan: {$result['updated']} wilayah diperbarui, {$result['failed']} gagal; cache lama dipertahankan untuk wilayah gagal.");

                        continue;
                    }
                    $count = $result['updated'];
                    $statuses->succeeded($statusKey, $count);
                    $this->info("Prakiraan BMKG berhasil diperiksa untuk {$count} wilayah.");

                    continue;
                }

                $count = $result;
                $statuses->succeeded($statusKey, $count);
                if ($feed === 'earthquakes') {
                    $this->info($count === 0
                        ? 'Feed gempa BMKG valid; tidak ada catatan yang memenuhi cakupan Sumatera Barat.'
                        : "Feed gempa BMKG valid; catatan yang memenuhi cakupan Sumatera Barat: {$count}.");
                } else {
                    $this->info($count === 0
                        ? 'Feed peringatan BMKG valid; tidak ada peringatan aktif untuk Sumatera Barat.'
                        : "Feed peringatan BMKG valid; peringatan aktif untuk Sumatera Barat: {$count}.");
                }
            } catch (Throwable $exception) {
                $hasFailures = true;
                $category = $this->failureCategory($exception);
                $statuses->failed($statusKey, $category);
                $this->logFailure($statusKey, $exception, $category);
                $this->error("Sinkronisasi {$statusKey} gagal; data tersimpan sebelumnya dipertahankan.");
            }
        }

        return $hasFailures ? self::FAILURE : self::SUCCESS;
    }

    private function failureCategory(Throwable $exception): string
    {
        return match (true) {
            $exception instanceof RequestException => 'http_status_failure',
            $exception instanceof ConnectionException && preg_match('/timed?\s*out|timeout/i', $exception->getMessage()) === 1 => 'timeout',
            $exception instanceof ConnectionException => 'connection_failure',
            $exception instanceof \UnexpectedValueException => 'feed_parse_or_validation',
            default => 'unexpected_or_persistence_failure',
        };
    }

    private function logFailure(string $feed, Throwable $exception, string $category): void
    {
        $context = [
            'feed' => $feed,
            'failure_category' => $category,
            'exception_class' => $exception::class,
        ];
        if ($exception instanceof RequestException) {
            $context['http_status'] = $exception->response->status();
        }
        // Never log response bodies, personal location data, or credentials.
        Log::warning('BMKG source synchronization failed; stored records were retained', $context);
    }
}
