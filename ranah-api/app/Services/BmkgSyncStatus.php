<?php

namespace App\Services;

use Illuminate\Support\Facades\Cache;

class BmkgSyncStatus
{
    private const TTL_DAYS = 90;

    /** @return array<string, mixed> */
    public function get(string $feed): array
    {
        $status = Cache::get($this->key($feed));

        return is_array($status) ? $status : [
            'status' => 'belum_diperiksa',
            'last_attempt_at' => null,
            'last_success_at' => null,
            'error_code' => null,
            'records' => null,
        ];
    }

    public function attempted(string $feed): void
    {
        $status = $this->get($feed);
        $status['status'] = 'memeriksa';
        $status['last_attempt_at'] = now()->toIso8601String();
        $status['error_code'] = null;
        $this->put($feed, $status);
    }

    public function succeeded(string $feed, int $records): void
    {
        $status = $this->get($feed);
        $status['status'] = 'berhasil';
        $status['last_attempt_at'] = now()->toIso8601String();
        $status['last_success_at'] = now()->toIso8601String();
        $status['error_code'] = null;
        $status['records'] = $records;
        unset($status['failed_areas']);
        $this->put($feed, $status);
    }

    public function partial(string $feed, int $updated, int $failed): void
    {
        $status = $this->get($feed);
        $status['status'] = 'sebagian_gagal';
        $status['last_attempt_at'] = now()->toIso8601String();
        if ($updated > 0) {
            $status['last_success_at'] = now()->toIso8601String();
        }
        $status['error_code'] = 'sebagian_wilayah_gagal';
        $status['records'] = $updated;
        $status['failed_areas'] = $failed;
        $this->put($feed, $status);
    }

    public function failed(string $feed, string $errorCode): void
    {
        $status = $this->get($feed);
        $status['status'] = 'gagal';
        $status['last_attempt_at'] = now()->toIso8601String();
        $status['error_code'] = $errorCode;
        $this->put($feed, $status);
    }

    public function unavailable(string $feed, string $reason): void
    {
        $status = $this->get($feed);
        $status['status'] = $reason;
        $status['last_attempt_at'] = now()->toIso8601String();
        $status['error_code'] = null;
        $this->put($feed, $status);
    }

    private function put(string $feed, array $status): void
    {
        Cache::put($this->key($feed), $status, now()->addDays(self::TTL_DAYS));
    }

    private function key(string $feed): string
    {
        return 'bmkg_sync_status_'.$feed;
    }
}
