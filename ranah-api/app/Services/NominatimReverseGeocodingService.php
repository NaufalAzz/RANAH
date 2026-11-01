<?php

namespace App\Services;

use Illuminate\Cache\LockTimeoutException;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Http;
use RuntimeException;

class NominatimReverseGeocodingService
{
    private const CACHE_MINUTES = 10;
    private const MINIMUM_INTERVAL_SECONDS = 1.0;
    private const LOCK_KEY = 'ranah:nominatim:reverse:global-lock';
    private const LAST_REQUEST_KEY = 'ranah:nominatim:reverse:last-request';
    private const COOLDOWN_KEY = 'ranah:nominatim:reverse:cooldown-until';

    /** @return array<string, mixed> */
    public function reverse(float $latitude, float $longitude): array
    {
        $cache = Cache::store('file');
        $coordinateKey = sprintf('%.5f,%.5f', $latitude, $longitude);
        $cacheKey = 'ranah:nominatim:reverse:' . hash('sha256', $coordinateKey);
        $cached = $cache->get($cacheKey);
        if (is_array($cached)) {
            return $cached;
        }

        try {
            return $cache->lock(self::LOCK_KEY, 30)->block(20, function () use (
                $cache,
                $cacheKey,
                $latitude,
                $longitude,
            ): array {
                $cached = $cache->get($cacheKey);
                if (is_array($cached)) {
                    return $cached;
                }

                $cooldownUntil = (float) $cache->get(self::COOLDOWN_KEY, 0);
                if ($cooldownUntil > microtime(true)) {
                    throw new NominatimLookupException(
                        'Layanan alamat membatasi permintaan sementara.',
                        429,
                        (int) ceil($cooldownUntil - microtime(true)),
                    );
                }

                $lastRequestAt = (float) $cache->get(self::LAST_REQUEST_KEY, 0);
                $waitSeconds = self::MINIMUM_INTERVAL_SECONDS -
                    (microtime(true) - $lastRequestAt);
                if ($waitSeconds > 0) {
                    usleep((int) ceil($waitSeconds * 1_000_000));
                }

                $cache->put(self::LAST_REQUEST_KEY, microtime(true), now()->addMinutes(2));
                try {
                    $response = Http::acceptJson()
                        ->withUserAgent('RANAH/1.0 (' . config('app.url') . ')')
                        ->timeout(12)
                        ->get('https://nominatim.openstreetmap.org/reverse', [
                            'format' => 'jsonv2',
                            'addressdetails' => 1,
                            'accept-language' => 'id',
                            'zoom' => 18,
                            'lat' => $latitude,
                            'lon' => $longitude,
                        ]);
                } catch (\Illuminate\Http\Client\ConnectionException) {
                    throw new NominatimLookupException('Layanan alamat tidak dapat dihubungi.', 502);
                }

                if ($response->status() === 429) {
                    $retryAfter = max(1, (int) $response->header('Retry-After', 5));
                    $cache->put(
                        self::COOLDOWN_KEY,
                        microtime(true) + $retryAfter,
                        now()->addSeconds($retryAfter),
                    );
                    throw new NominatimLookupException(
                        'Layanan alamat membatasi permintaan sementara.',
                        429,
                        $retryAfter,
                    );
                }

                if (! $response->successful()) {
                    throw new NominatimLookupException('Layanan alamat gagal merespons.', 502);
                }

                $payload = $response->json();
                if (! is_array($payload) || ! is_array($payload['address'] ?? null)) {
                    throw new NominatimLookupException('Format alamat dari layanan peta tidak valid.', 502);
                }

                $result = [
                    'address' => $payload['address'],
                    'display_name' => $this->nullableText($payload['display_name'] ?? null),
                    'sumber' => 'Nominatim / OpenStreetMap',
                    'url_atribusi' => 'https://www.openstreetmap.org/copyright',
                    'waktu_pengambilan' => now()->toIso8601String(),
                ];
                $cache->put($cacheKey, $result, now()->addMinutes(self::CACHE_MINUTES));

                return $result;
            });
        } catch (LockTimeoutException) {
            throw new NominatimLookupException(
                'Layanan alamat sedang menangani permintaan lain. Coba lagi sebentar.',
                429,
                1,
            );
        }
    }

    private function nullableText(mixed $value): ?string
    {
        if (! is_string($value)) {
            return null;
        }

        $value = trim($value);

        return $value === '' ? null : $value;
    }
}

class NominatimLookupException extends RuntimeException
{
    public function __construct(
        string $message,
        public readonly int $httpStatus,
        public readonly int $retryAfterSeconds = 0,
    ) {
        parent::__construct($message);
    }
}
