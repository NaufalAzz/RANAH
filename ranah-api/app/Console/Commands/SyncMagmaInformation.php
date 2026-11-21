<?php

namespace App\Console\Commands;

use App\Services\MagmaInformationService;
use Illuminate\Console\Attributes\Description;
use Illuminate\Console\Attributes\Signature;
use Illuminate\Console\Command;
use Illuminate\Http\Client\ConnectionException;
use Illuminate\Http\Client\RequestException;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Log;
use RuntimeException;
use Throwable;

#[Signature('ranah:sync-magma {--gunung= : Simpan satu laporan terbaru untuk nama gunung yang dipilih} {--semua-laporan : Lengkapi laporan seluruh gunung secara bertahap}')]
#[Description('Sinkronisasi manual berfrekuensi rendah dari halaman publik MAGMA Indonesia.')]
class SyncMagmaInformation extends Command
{
    public function handle(MagmaInformationService $service): int
    {
        if ($this->option('semua-laporan') && trim((string) $this->option('gunung')) !== '') {
            $this->error('Pilih --gunung atau --semua-laporan, bukan keduanya.');

            return self::INVALID;
        }
        $lock = Cache::lock('ranah:magma-sync-lock', $this->option('semua-laporan') ? 1800 : 90);
        if (! $lock->get()) {
            $this->warn('Sinkronisasi MAGMA lain sedang berjalan. Tidak ada permintaan baru yang dikirim.');

            return self::FAILURE;
        }

        try {
            $cooldownKey = $this->option('semua-laporan') ? 'ranah:magma-all-reports-next-allowed-at' : 'ranah:magma-next-allowed-at';
            $nextAllowedAt = Cache::get($cooldownKey);
            $sourceBackoff = Cache::get('ranah:magma-source-backoff-until');
            if ($sourceBackoff instanceof \DateTimeInterface && ($nextAllowedAt === null || $sourceBackoff > $nextAllowedAt)) {
                $nextAllowedAt = $sourceBackoff;
            }
            if ($nextAllowedAt instanceof \DateTimeInterface && $nextAllowedAt > now()) {
                $this->warn('Sinkronisasi MAGMA dibatasi frekuensinya; coba lagi setelah '.$nextAllowedAt->format('d/m/Y H:i T').'.');

                return self::FAILURE;
            }

            if ($this->option('semua-laporan')) {
                $this->info('Melengkapi laporan satu per satu. Laporan lengkap dilewati; jeda antarunduhan 3 detik.');
                $summary = $service->synchronizeAllReports(fn (string $name, string $status) => $this->line($name.' — '.$status));
                $this->info('Total: '.$summary['total'].' | Terisi: '.$summary['updated'].' | Sudah terisi: '.$summary['skipped']
                    .' | Sumber belum menyediakan rekomendasi: '.$summary['missing'].' | Gagal: '.$summary['failed'].' | Belum diproses: '.$summary['remaining']);
                $retryAt = $summary['halted_status'] === 429 ? now()->addSeconds($summary['retry_after_seconds'])
                    : ($summary['failed'] > 0 || $summary['missing'] > 0 ? now()->addMinutes(15) : now()->addHours(6));
                Cache::put($cooldownKey, $retryAt, $retryAt);
                if ($summary['halted_status'] !== null) {
                    Cache::put('ranah:magma-source-backoff-until', $retryAt, $retryAt);
                    $this->warn('Proses dihentikan karena sumber menolak atau membatasi akses. Data yang berhasil tetap tersimpan.');
                }

                return $summary['failed'] + $summary['missing'] + $summary['remaining'] === 0 ? self::SUCCESS : self::FAILURE;
            }

            $name = trim((string) $this->option('gunung'));
            $count = $service->synchronizeActivityListing($name !== '' ? $name : null);
            $this->info("Daftar status MAGMA berhasil diproses: {$count} gunung yang tercantum.");
            $this->warn('Daftar ini bukan inventaris lengkap seluruh gunung api Indonesia. Data yang tidak tercantum tidak dinonaktifkan.');

            if ($name !== '') {
                $this->info("Satu laporan MAGMA untuk {$name} disimpan atau diperbarui.");
            }

            Cache::put('ranah:magma-next-allowed-at', now()->addHours(6), now()->addHours(6));

            return self::SUCCESS;
        } catch (Throwable $exception) {
            $failureUntil = now()->addMinutes(15);
            Cache::put($cooldownKey, $failureUntil, $failureUntil);
            Cache::put('ranah:magma-source-backoff-until', $failureUntil, $failureUntil);
            $context = ['exception_class' => $exception::class];
            if ($exception instanceof RequestException) {
                $context['http_status'] = $exception->response->status();
                $context['failure_category'] = $exception->response->status() === 429 ? 'rate_limited' : 'http_status_failure';
                if ($exception->response->status() === 429) {
                    $retryAfter = $exception->response->header('Retry-After');
                    $retrySeconds = is_string($retryAfter) && ctype_digit($retryAfter) ? max(3600, (int) $retryAfter) : 3600;
                    $failureUntil = now()->addSeconds($retrySeconds);
                    Cache::put($cooldownKey, $failureUntil, $failureUntil);
                    Cache::put('ranah:magma-source-backoff-until', $failureUntil, $failureUntil);
                }
            } elseif ($exception instanceof ConnectionException) {
                $context['failure_category'] = preg_match('/timed?\s*out|timeout/i', $exception->getMessage()) === 1
                    ? 'timeout'
                    : 'connection_failure';
            } elseif ($exception instanceof RuntimeException) {
                $context['failure_category'] = 'invalid_or_unrecognized_source_response';
            } else {
                $context['failure_category'] = 'connection_or_persistence_failure';
            }
            Log::warning('MAGMA synchronization failed; stored volcano data was retained', $context);
            $this->error('Sinkronisasi MAGMA gagal; data yang tersimpan sebelumnya dipertahankan. Periksa log untuk kategori kegagalan.');

            return self::FAILURE;
        } finally {
            $lock->release();
        }
    }
}
