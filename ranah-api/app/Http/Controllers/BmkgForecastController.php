<?php

namespace App\Http\Controllers;

use App\Services\BmkgForecastService;
use App\Services\BmkgSyncStatus;
use Carbon\CarbonImmutable;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class BmkgForecastController extends Controller
{
    public function areas(BmkgForecastService $forecasts, BmkgSyncStatus $statuses): JsonResponse
    {
        return response()->json([
            'success' => true,
            'message' => $forecasts->configuredAreas() === []
                ? 'Belum ada kode ADM4 Sumatera Barat yang tervalidasi dan dikonfigurasi.'
                : 'Daftar wilayah prakiraan BMKG yang dikonfigurasi.',
            'data' => array_map(static fn (array $area): array => [
                'adm4' => $area['adm4'],
                'desa' => $area['desa'],
                'kecamatan' => $area['kecamatan'],
                'kotkab' => $area['kotkab'],
                'provinsi' => $area['provinsi'],
            ], $forecasts->configuredAreas()),
            'meta' => ['status_sinkronisasi' => $statuses->get('forecasts')],
        ]);
    }

    public function show(
        Request $request,
        string $adm4,
        BmkgForecastService $forecasts,
        BmkgSyncStatus $statuses,
    ): JsonResponse {
        $area = collect($forecasts->configuredAreas())->firstWhere('adm4', $adm4);
        if ($area === null) {
            return response()->json([
                'success' => false,
                'message' => 'Kode wilayah ini belum tersedia dalam daftar ADM4 Sumatera Barat yang diverifikasi.',
                'error_code' => 'wilayah_belum_terkonfigurasi',
            ], 404);
        }

        $cached = $forecasts->cachedForecast($adm4);
        if ($cached === null) {
            return response()->json([
                'success' => true,
                'message' => 'Prakiraan belum tersedia; sinkronisasi terjadwal belum berhasil untuk wilayah ini.',
                'data' => null,
                'meta' => [
                    'status' => 'belum_tersedia',
                    'status_sinkronisasi' => $statuses->get('forecasts'),
                ],
            ]);
        }

        $now = now();
        $cached['prakiraan'] = array_values(array_filter(
            $cached['prakiraan'] ?? [],
            static fn (array $item): bool => CarbonImmutable::parse($item['waktu_utc'])->greaterThan($now),
        ));
        $createdAt = isset($cached['waktu_data_dibuat'])
            ? CarbonImmutable::parse($cached['waktu_data_dibuat'])
            : null;
        $staleHours = max(1, (int) config('bmkg.forecast_stale_hours', 18));
        $isStale = $createdAt === null || $createdAt->lessThan($now->copy()->subHours($staleHours));
        $status = $cached['prakiraan'] === [] ? 'prakiraan_kedaluwarsa' : ($isStale ? 'data_lama' : 'tersedia');

        return response()->json([
            'success' => true,
            'message' => $status === 'tersedia'
                ? 'Prakiraan BMKG tersedia untuk wilayah terpilih.'
                : ($status === 'data_lama'
                    ? 'Data terakhir masih ditampilkan dengan penanda waktu lama.'
                    : 'Tidak ada interval prakiraan mendatang pada data tersimpan.'),
            'data' => $cached,
            'meta' => [
                'status' => $status,
                'data_stale' => $isStale,
                'status_sinkronisasi' => $statuses->get('forecasts'),
            ],
        ]);
    }
}
