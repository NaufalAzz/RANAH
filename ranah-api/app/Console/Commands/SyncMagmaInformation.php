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

#[Signature('ranah:sync-magma {--gunung= : Simpan satu laporan terbaru untuk nama gunung yang dipilih}')]
#[Description('Sinkronisasi manual berfrekuensi rendah dari halaman publik MAGMA Indonesia.')]
class SyncMagmaInformation extends Command
{
    public function handle(MagmaInformationService $service): int
    {
        $lock = Cache::lock('ranah:magma-sync-lock', 90);
        if (! $lock->get()) {
            $this->warn('Sinkronisasi MAGMA lain sedang berjalan. Tidak ada permintaan baru yang dikirim.');

            return self::FAILURE;
        }

        try {
            $nextAllowedAt = Cache::get('ranah:magma-next-allowed-at');
            if ($nextAllowedAt instanceof \DateTimeInterface && $nextAllowedAt > now()) {
                $this->warn('Sinkronisasi MAGMA dibatasi frekuensinya; coba lagi setelah '.$nextAllowedAt->format('d/m/Y H:i T').'.');

                return self::FAILURE;
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
            Cache::put('ranah:magma-next-allowed-at', now()->addMinutes(15), now()->addMinutes(15));
            $context = ['exception_class' => $exception::class];
            if ($exception instanceof RequestException) {
                $context['http_status'] = $exception->response->status();
                $context['failure_category'] = $exception->response->status() === 429 ? 'rate_limited' : 'http_status_failure';
                if ($exception->response->status() === 429) {
                    Cache::put('ranah:magma-next-allowed-at', now()->addHour(), now()->addHour());
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
