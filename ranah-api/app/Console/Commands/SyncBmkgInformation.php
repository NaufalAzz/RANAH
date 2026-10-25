<?php

namespace App\Console\Commands;

use App\Services\BmkgInformationService;
use Illuminate\Console\Attributes\Description;
use Illuminate\Console\Attributes\Signature;
use Illuminate\Console\Command;
use Illuminate\Http\Client\ConnectionException;
use Illuminate\Http\Client\RequestException;
use Illuminate\Support\Facades\Log;
use Throwable;

#[Signature('ranah:sync-bmkg')]
#[Description('Sinkronkan laporan gempa dan peringatan cuaca resmi BMKG yang relevan dengan Sumatera Barat.')]
class SyncBmkgInformation extends Command
{
    public function handle(BmkgInformationService $service): int
    {
        $hasFailures = false;

        try {
            $count = $service->synchronizeFeltEarthquakes();
            $this->info($count === 0
                ? 'Feed gempa BMKG valid; tidak ada catatan yang memenuhi cakupan Sumatera Barat.'
                : "Feed gempa BMKG valid; catatan yang memenuhi cakupan Sumatera Barat: {$count}.");
        } catch (Throwable $exception) {
            $hasFailures = true;
            $this->logFailure('earthquakes', $exception);
            $this->error('Sinkronisasi gempa BMKG gagal; data tersimpan sebelumnya dipertahankan.');
        }

        try {
            $count = $service->synchronizeWestSumatraWeatherAlerts();
            $this->info($count === 0
                ? 'Feed peringatan BMKG valid; tidak ada peringatan aktif untuk Sumatera Barat.'
                : "Feed peringatan BMKG valid; peringatan aktif untuk Sumatera Barat: {$count}.");
        } catch (Throwable $exception) {
            $hasFailures = true;
            $this->logFailure('weather_alerts', $exception);
            $this->error('Sinkronisasi peringatan BMKG gagal; data tersimpan sebelumnya dipertahankan.');
        }

        return $hasFailures ? self::FAILURE : self::SUCCESS;
    }

    private function logFailure(string $feed, Throwable $exception): void
    {
        $category = match (true) {
            $exception instanceof RequestException => 'http_status_failure',
            $exception instanceof ConnectionException && preg_match('/timed?\s*out|timeout/i', $exception->getMessage()) === 1 => 'timeout',
            $exception instanceof ConnectionException => 'connection_failure',
            $exception instanceof \UnexpectedValueException => 'feed_parse_or_validation',
            default => 'unexpected_or_persistence_failure',
        };
        $context = [
            'feed' => $feed,
            'failure_category' => $category,
            'exception_class' => $exception::class,
        ];
        if ($exception instanceof RequestException) {
            $context['http_status'] = $exception->response->status();
        }

        // Never log response bodies, credentials, or request headers.
        Log::warning('BMKG source synchronization failed; stored records were retained', $context);
    }
}
