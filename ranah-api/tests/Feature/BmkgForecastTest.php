<?php

namespace Tests\Feature;

use App\Services\BmkgForecastService;
use App\Services\BmkgSyncStatus;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Http;
use Tests\TestCase;

class BmkgForecastTest extends TestCase
{
    use RefreshDatabase;

    // Synthetic test-only ADM4-shaped value; it is not a real location mapping.
    private const ADM4 = '13.71.99.9999';

    protected function setUp(): void
    {
        parent::setUp();
        config(['bmkg.weather_areas' => [$this->area()]]);
    }

    public function test_valid_forecast_is_normalized_cached_and_returned_by_allowlisted_api(): void
    {
        Http::fake([
            'https://api.bmkg.go.id/publik/prakiraan-cuaca*' => Http::response($this->payload(), 200),
        ]);

        $result = app(BmkgForecastService::class)->synchronizeConfiguredAreas();

        $this->assertSame(['updated' => 1, 'failed' => 0, 'skipped' => false], $result);
        Http::assertSent(fn ($request): bool => $request->url() === 'https://api.bmkg.go.id/publik/prakiraan-cuaca?adm4='.self::ADM4);
        $this->getJson('/api/prakiraan-cuaca/wilayah')
            ->assertOk()
            ->assertJsonPath('data.0.adm4', self::ADM4)
            ->assertJsonPath('data.0.provinsi', 'Sumatera Barat');
        $this->getJson('/api/prakiraan-cuaca/'.self::ADM4)
            ->assertOk()
            ->assertJsonPath('meta.status', 'tersedia')
            ->assertJsonPath('data.prakiraan.0.kondisi', 'Hujan Ringan')
            ->assertJsonPath('data.prakiraan.0.suhu_c', 24);
    }

    public function test_unverified_or_non_sumbar_adm4_is_not_fetched_or_exposed(): void
    {
        config(['bmkg.weather_areas' => [
            $this->area(['adm4' => '13.71.98.8888', 'terverifikasi' => false]),
            $this->area(['adm4' => '32.73.01.1001', 'provinsi' => 'Jawa Barat']),
        ]]);
        Http::fake();

        $this->assertSame([], app(BmkgForecastService::class)->configuredAreas());
        $this->assertSame(['updated' => 0, 'failed' => 0, 'skipped' => true], app(BmkgForecastService::class)->synchronizeConfiguredAreas());
        $this->getJson('/api/prakiraan-cuaca/13.71.01.1001')->assertNotFound();
        Http::assertNothingSent();
    }

    public function test_source_location_mismatch_fails_and_preserves_previous_cache(): void
    {
        $key = 'bmkg_forecast_13_71_01_1001';
        $old = ['wilayah' => $this->area(), 'prakiraan' => [['kondisi' => 'Data tersimpan lama']]];
        Cache::put($key, $old);
        Http::fake([
            'https://api.bmkg.go.id/publik/prakiraan-cuaca*' => Http::response($this->payload(['desa' => 'Kelurahan Lain']), 200),
        ]);

        $result = app(BmkgForecastService::class)->synchronizeConfiguredAreas();

        $this->assertSame(0, $result['updated']);
        $this->assertSame(1, $result['failed']);
        $this->assertSame($old, Cache::get($key));
    }

    public function test_expired_intervals_are_not_returned_as_upcoming_forecast(): void
    {
        $area = $this->area();
        Cache::put('bmkg_forecast_13_71_99_9999', [
            'wilayah' => $area,
            'prakiraan' => [[
                'waktu_lokal' => now()->subHour()->toIso8601String(),
                'waktu_utc' => now()->subHour()->utc()->toIso8601String(),
                'kondisi' => 'Fixture lama',
                'suhu_c' => 24,
                'kelembapan_persen' => 80,
                'kecepatan_angin_kmh' => 2,
            ]],
            'waktu_data_dibuat' => now()->subHour()->toIso8601String(),
            'waktu_diambil' => now()->subHour()->toIso8601String(),
            'sumber' => 'Fixture test only',
            'url_sumber' => 'https://api.bmkg.go.id/publik/prakiraan-cuaca?adm4=13.71.99.9999',
        ]);

        $this->getJson('/api/prakiraan-cuaca/'.self::ADM4)
            ->assertOk()
            ->assertJsonPath('meta.status', 'prakiraan_kedaluwarsa')
            ->assertJsonPath('data.prakiraan', []);
    }

    public function test_local_forecast_datetime_without_offset_uses_configured_jakarta_timezone(): void
    {
        config(['bmkg.schedules.forecast_timezone' => 'Asia/Jakarta']);
        $payload = $this->payload();
        $local = now('Asia/Jakarta')->addHours(3)->format('Y-m-d H:i:s');
        $utc = now('UTC')->addHours(3)->format('Y-m-d H:i:s');
        $payload['data'][0]['cuaca'][0][0]['local_datetime'] = $local;
        $payload['data'][0]['cuaca'][0][0]['utc_datetime'] = $utc;
        Http::fake([
            'https://api.bmkg.go.id/publik/prakiraan-cuaca*' => Http::response($payload, 200),
        ]);

        app(BmkgForecastService::class)->synchronizeConfiguredAreas();

        $forecast = app(BmkgForecastService::class)->cachedForecast(self::ADM4);
        $this->assertSame(
            str_replace(' ', 'T', $local).'+07:00',
            $forecast['prakiraan'][0]['waktu_lokal'],
        );
        $this->assertSame(str_replace(' ', 'T', $utc).'+00:00', $forecast['prakiraan'][0]['waktu_utc']);
    }

    public function test_invalid_adm4_configuration_is_excluded(): void
    {
        config(['bmkg.weather_areas' => [$this->area(['adm4' => '13.71.01.1'])]]);

        $this->assertSame([], app(BmkgForecastService::class)->configuredAreas());
    }

    public function test_command_marks_all_failed_forecast_areas_as_failed_not_partial(): void
    {
        config(['bmkg.weather_areas' => [[
            'adm4' => self::ADM4,
            'desa' => 'Kelurahan Fixture',
            'kecamatan' => 'Kecamatan Fixture',
            'kotkab' => 'Kota Fixture',
            'provinsi' => 'Sumatera Barat',
            'sumber_kode' => 'https://www.bmkg.go.id/cuaca/prakiraan-cuaca/'.self::ADM4,
            'terverifikasi' => true,
        ]]]);
        Http::fake([
            'https://api.bmkg.go.id/publik/prakiraan-cuaca*' => Http::failedConnection('cURL error 7: connection refused'),
        ]);

        $this->artisan('ranah:sync-bmkg --feed=forecasts')->assertExitCode(1);

        $this->assertSame('gagal', app(BmkgSyncStatus::class)->get('forecasts')['status']);
        $this->assertSame('all_configured_areas_failed', app(BmkgSyncStatus::class)->get('forecasts')['error_code']);
    }

    public function test_successful_sync_clears_failure_count_from_previous_partial_sync(): void
    {
        $statuses = app(BmkgSyncStatus::class);
        $statuses->partial('forecasts', 1, 1);

        $statuses->succeeded('forecasts', 1);

        $status = $statuses->get('forecasts');
        $this->assertSame('berhasil', $status['status']);
        $this->assertSame(1, $status['records']);
        $this->assertNotNull($status['last_success_at']);
        $this->assertArrayNotHasKey('failed_areas', $status);
        $this->assertNull($status['error_code']);
    }

    public function test_official_bmkg_weather_page_can_provenance_a_verified_pilot_area(): void
    {
        config(['bmkg.weather_areas' => [[
            'adm4' => '13.71.09.1001',
            'desa' => 'Pasar Ambacang',
            'kecamatan' => 'Kuranji',
            'kotkab' => 'Kota Padang',
            'provinsi' => 'Sumatera Barat',
            'sumber_kode' => 'https://www.bmkg.go.id/cuaca/prakiraan-cuaca/13.71.09.1001',
            'terverifikasi' => true,
        ]]]);

        $areas = app(BmkgForecastService::class)->configuredAreas();

        $this->assertCount(1, $areas);
        $this->assertSame('13.71.09.1001', $areas[0]['adm4']);
        $this->assertSame('Pasar Ambacang', $areas[0]['desa']);
    }

    public function test_weather_areas_api_returns_the_configured_pilot_contract(): void
    {
        config(['bmkg.weather_areas' => [[
            'adm4' => '13.71.09.1001',
            'desa' => 'Pasar Ambacang',
            'kecamatan' => 'Kuranji',
            'kotkab' => 'Kota Padang',
            'provinsi' => 'Sumatera Barat',
            'sumber_kode' => 'https://www.bmkg.go.id/cuaca/prakiraan-cuaca/13.71.09.1001',
            'terverifikasi' => true,
        ]]]);

        $this->getJson('/api/prakiraan-cuaca/wilayah')
            ->assertOk()
            ->assertJsonPath('data.0.adm4', '13.71.09.1001')
            ->assertJsonPath('data.0.desa', 'Pasar Ambacang')
            ->assertJsonPath('data.0.kecamatan', 'Kuranji')
            ->assertJsonPath('data.0.kotkab', 'Kota Padang')
            ->assertJsonPath('data.0.provinsi', 'Sumatera Barat');
    }

    public function test_missing_live_cache_is_reported_as_unavailable_not_as_empty_successful_forecast(): void
    {
        config(['bmkg.weather_areas' => [[
            'adm4' => '13.71.09.1001',
            'desa' => 'Pasar Ambacang',
            'kecamatan' => 'Kuranji',
            'kotkab' => 'Kota Padang',
            'provinsi' => 'Sumatera Barat',
            'sumber_kode' => 'https://www.bmkg.go.id/cuaca/prakiraan-cuaca/13.71.09.1001',
            'terverifikasi' => true,
        ]]]);

        $this->getJson('/api/prakiraan-cuaca/13.71.09.1001')
            ->assertOk()
            ->assertJsonPath('success', true)
            ->assertJsonPath('data', null)
            ->assertJsonPath('meta.status', 'belum_tersedia')
            ->assertJsonPath('meta.status_sinkronisasi.status', 'belum_diperiksa');
    }

    /** @return array<string, mixed> */
    private function area(array $overrides = []): array
    {
        return array_merge([
            'adm4' => self::ADM4,
            'desa' => 'Kelurahan Fixture',
            'kecamatan' => 'Kecamatan Fixture',
            'kotkab' => 'Kota Fixture',
            'provinsi' => 'Sumatera Barat',
            'sumber_kode' => 'Kemendagri Kepmendagri 300.2.2-2430 Tahun 2025',
            'terverifikasi' => true,
        ], $overrides);
    }

    /** @return array<string, mixed> */
    private function payload(array $locationOverrides = []): array
    {
        $interval = [
            'utc_datetime' => now()->addHours(3)->utc()->toIso8601String(),
            'local_datetime' => now()->addHours(10)->toIso8601String(),
            'weather_desc' => 'Hujan Ringan',
            't' => 24,
            'hu' => 85,
            'ws' => 8,
            'analysis_date' => now()->toIso8601String(),
        ];

        return [
            'lokasi' => array_merge([
                'adm4' => self::ADM4,
                'desa' => 'Kelurahan Fixture',
                'kecamatan' => 'Kecamatan Fixture',
                'kotkab' => 'Kota Fixture',
                'provinsi' => 'Sumatera Barat',
            ], $locationOverrides),
            'data' => [['cuaca' => [[$interval]]]],
        ];
    }
}
