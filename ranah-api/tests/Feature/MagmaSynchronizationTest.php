<?php

namespace Tests\Feature;

use App\Models\Gunung;
use App\Services\MagmaInformationService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\Client\RequestException;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Http;
use Tests\TestCase;

class MagmaSynchronizationTest extends TestCase
{
    use RefreshDatabase;

    public function test_fixture_listing_updates_existing_row_without_duplicates_and_is_available_from_api(): void
    {
        $gunung = Gunung::query()->create([
            'nama' => 'Gunung Merapi', 'provinsi' => 'Jawa Tengah', 'kabupaten' => 'Kabupaten Magelang',
            'sumber_data' => 'Data uji lokal', 'aktif' => true,
        ]);
        $this->fakeListing();

        $service = app(MagmaInformationService::class);
        self::assertSame(1, $service->synchronizeActivityListing());
        self::assertSame(1, $service->synchronizeActivityListing());
        self::assertDatabaseCount('gunung', 1);
        Http::assertSentCount(2);

        $this->getJson('/api/gunung')->assertOk()
            ->assertJsonPath('data.0.id', $gunung->id)
            ->assertJsonPath('data.0.sumber_id', null)
            ->assertJsonPath('data.0.status_aktivitas', 'Level III (Siaga)')
            ->assertJsonPath('data.0.sumber_data', 'MAGMA Indonesia')
            ->assertJsonStructure(['data' => [['waktu_pengambilan']]]);
    }

    public function test_activity_status_change_is_notified_with_source_capture_time_only(): void
    {
        Gunung::query()->create([
            'nama' => 'Gunung Merapi',
            'provinsi' => 'Jawa Tengah',
            'status_aktivitas' => 'Level II (Waspada)',
            'sumber_data' => 'MAGMA Indonesia',
            'aktif' => true,
        ]);
        $this->fakeListing();

        $service = app(MagmaInformationService::class);
        self::assertSame(1, $service->synchronizeActivityListing());
        self::assertSame(1, $service->synchronizeActivityListing());
        self::assertDatabaseCount('berita', 1);
        self::assertDatabaseHas('berita', [
            'sumber_id' => 'magma-status:'.hash('sha256', '123|Level II (Waspada)|Level III (Siaga)'),
            'waktu_publikasi' => null,
            'waktu_kejadian' => null,
        ]);
        $this->getJson('/api/notifikasi')
            ->assertOk()
            ->assertJsonCount(1, 'data')
            ->assertJsonPath('data.0.judul', 'Perubahan tingkat aktivitas Merapi')
            ->assertJsonPath('data.0.waktu_publikasi', null)
            ->assertJsonPath('data.0.waktu_pengambilan', fn ($value) => is_string($value))
            ->assertJsonPath('data.0.url_sumber', 'https://magma.esdm.go.id/v1/gunung-api/laporan/123?signature=fixture');
    }

    public function test_sanitized_actual_page_excerpt_is_persisted_and_exposed_by_the_normal_api(): void
    {
        $html = file_get_contents(__DIR__.'/../Fixtures/magma_activity_listing_capture_2026-10-25.html');
        self::assertIsString($html);
        Http::fake([
            'magma.esdm.go.id/v1/gunung-api/tingkat-aktivitas' => Http::response(
                $html,
                200,
                ['Content-Type' => 'text/html; charset=UTF-8'],
            ),
        ]);

        $service = app(MagmaInformationService::class);
        self::assertSame(2, $service->synchronizeActivityListing());
        self::assertSame(2, $service->synchronizeActivityListing());
        self::assertDatabaseCount('gunung', 2);

        $this->getJson('/api/gunung')->assertOk()
            ->assertJsonCount(2, 'data')
            ->assertJsonPath('data.0.status_aktivitas', 'Level III (Siaga)')
            ->assertJsonPath('data.1.status_aktivitas', 'Level III (Siaga)')
            ->assertJsonStructure(['data' => [['waktu_pengambilan']]]);
        Http::assertSentCount(2);
    }

    public function test_http_429_preserves_the_last_saved_volcano_status(): void
    {
        $gunung = Gunung::query()->create([
            'nama' => 'Gunung Merapi', 'provinsi' => 'Jawa Tengah', 'status_aktivitas' => 'Belum diverifikasi',
            'sumber_data' => 'Data uji lokal', 'aktif' => true,
        ]);
        Http::fake(['magma.esdm.go.id/*' => Http::response('slow down', 429)]);

        try {
            app(MagmaInformationService::class)->synchronizeActivityListing();
            self::fail('Expected a rate-limit failure.');
        } catch (RequestException $exception) {
            self::assertSame(429, $exception->response->status());
        }

        self::assertDatabaseHas('gunung', [
            'id' => $gunung->id,
            'status_aktivitas' => 'Belum diverifikasi',
            'sumber_data' => 'Data uji lokal',
        ]);
    }

    public function test_http_403_preserves_the_last_saved_volcano_status(): void
    {
        $gunung = Gunung::query()->create([
            'nama' => 'Gunung Merapi', 'provinsi' => 'Jawa Tengah', 'status_aktivitas' => 'Level I (Normal)',
            'sumber_data' => 'Data uji lokal', 'aktif' => true,
        ]);
        Http::fake(['magma.esdm.go.id/*' => Http::response('Forbidden', 403)]);

        try {
            app(MagmaInformationService::class)->synchronizeActivityListing();
            self::fail('Expected a forbidden response failure.');
        } catch (RequestException $exception) {
            self::assertSame(403, $exception->response->status());
        }

        self::assertDatabaseHas('gunung', [
            'id' => $gunung->id,
            'status_aktivitas' => 'Level I (Normal)',
            'sumber_data' => 'Data uji lokal',
        ]);
    }

    public function test_incomplete_source_html_does_not_partially_update_existing_records(): void
    {
        $gunung = Gunung::query()->create([
            'nama' => 'Gunung Merapi', 'provinsi' => 'Jawa Tengah', 'status_aktivitas' => 'Belum diverifikasi',
            'sumber_data' => 'Data uji lokal', 'aktif' => true,
        ]);
        Http::fake([
            'magma.esdm.go.id/v1/gunung-api/tingkat-aktivitas' => Http::response(
                '<table><tr><td>Level III (Siaga)</td></tr><tr><td>record not complete</td><td><a href="https://magma.esdm.go.id/v1/gunung-api/laporan/123?signature=fixture">Lihat laporan</a></td></tr></table>',
                200, ['Content-Type' => 'text/html'],
            ),
        ]);

        try {
            app(MagmaInformationService::class)->synchronizeActivityListing();
            self::fail('Expected incomplete source markup to fail validation.');
        } catch (\RuntimeException) {
            self::assertTrue(true);
        }

        self::assertDatabaseHas('gunung', [
            'id' => $gunung->id,
            'status_aktivitas' => 'Belum diverifikasi',
            'sumber_data' => 'Data uji lokal',
        ]);
    }

    public function test_sync_command_respects_the_frequency_cooldown_without_sending_requests(): void
    {
        Cache::put('ranah:magma-next-allowed-at', now()->addHours(6), now()->addHours(6));
        Http::fake();

        $this->artisan('ranah:sync-magma')->assertExitCode(1);

        Http::assertNothingSent();
    }

    public function test_one_signed_detail_is_deduplicated_and_publication_is_separate_from_fetch_time(): void
    {
        $this->fakeListing();
        $service = app(MagmaInformationService::class);
        $service->synchronizeActivityListing();
        $gunung = Gunung::query()->where('nama', 'Merapi')->firstOrFail();
        $gunung->forceFill([
            'latitude' => -7.5,
            'longitude' => 110.5,
            'sumber_koordinat' => 'Sumber fixture BIG',
            'sumber_koordinat_id' => 'fixture-14',
            'status_validasi_koordinat' => 'terverifikasi',
        ])->save();
        Http::fake([
            'magma.esdm.go.id/v1/gunung-api/tingkat-aktivitas' => Http::response(
                $this->activityHtml(),
                200, ['Content-Type' => 'text/html'],
            ),
            'magma.esdm.go.id/v1/gunung-api/laporan/123*' => Http::response(
                '<html><head><title>Laporan Aktivitas Gunung Api - Gunung Merapi, Minggu - 25 Oktober 2026, periode 06:00-12:00 WIB</title></head>'
                .'<body><h2>Level III (Siaga)</h2><h3>Pengamatan Visual</h3><p>Asap kawah teramati.</p>'
                .'<h3>Rekomendasi</h3><p>Masyarakat mengikuti arahan resmi.</p><script>L.marker([-7.54,110.44])</script></body></html>',
                200, ['Content-Type' => 'text/html'],
            ),
        ]);

        self::assertSame(1, $service->synchronizeActivityListing('Gunung Merapi'));
        self::assertSame(1, $service->synchronizeActivityListing('Gunung Merapi'));
        self::assertDatabaseCount('laporan_gunung', 1);
        self::assertDatabaseHas('gunung', [
            'id' => $gunung->id,
            'latitude' => '-7.5000000',
            'longitude' => '110.5000000',
            'sumber_koordinat' => 'Sumber fixture BIG',
            'sumber_koordinat_id' => 'fixture-14',
            'status_validasi_koordinat' => 'terverifikasi',
        ]);
        $this->getJson('/api/gunung/1')->assertOk()
            ->assertJsonPath('data.laporan.0.sumber_id', '123')
            ->assertJsonPath('data.laporan.0.periode_waktu', '06:00-12:00 WIB')
            ->assertJsonPath('data.laporan.0.pengamatan_visual', 'Asap kawah teramati.')
            ->assertJsonPath('data.laporan.0.url_sumber', 'https://magma.esdm.go.id/v1/gunung-api/laporan/123?signature=fixture')
            ->assertJsonPath('data.laporan.0.waktu_publikasi', '2026-10-25T00:00:00.000000Z');
    }

    public function test_verified_magma_report_creates_one_feed_record_only_when_status_changed(): void
    {
        $gunung = Gunung::query()->create([
            'nama' => 'Gunung Merapi',
            'provinsi' => 'Jawa Tengah',
            'status_aktivitas' => 'Level II (Waspada)',
            'sumber_data' => 'MAGMA Indonesia',
            'aktif' => true,
        ]);
        Http::fake([
            'magma.esdm.go.id/v1/gunung-api/tingkat-aktivitas' => Http::response(
                $this->activityHtml(), 200, ['Content-Type' => 'text/html'],
            ),
            'magma.esdm.go.id/v1/gunung-api/laporan/123*' => Http::response(
                '<html><head><title>Laporan Aktivitas Gunung Api - Gunung Merapi, Minggu - 25 Oktober 2026, periode 06:00-12:00 WIB</title></head>'
                .'<body><h2>Level III (Siaga)</h2><h3>Pengamatan Visual</h3><p>Asap kawah teramati.</p>'
                .'<h3>Rekomendasi</h3><p>Masyarakat mengikuti arahan resmi.</p></body></html>',
                200, ['Content-Type' => 'text/html'],
            ),
        ]);

        $service = app(MagmaInformationService::class);
        self::assertSame(1, $service->synchronizeActivityListing('Merapi'));
        self::assertSame(1, $service->synchronizeActivityListing('Merapi'));

        self::assertDatabaseCount('berita', 1);
        $this->getJson('/api/notifikasi')
            ->assertOk()
            ->assertJsonCount(1, 'data')
            ->assertJsonPath('data.0.sumber', 'MAGMA Indonesia')
            ->assertJsonPath('data.0.sumber_id', 'magma-status:'.hash('sha256', '123|Level II (Waspada)|Level III (Siaga)'))
            ->assertJsonPath('data.0.status', 'informasi');
        self::assertDatabaseHas('gunung', [
            'id' => $gunung->id,
            'status_aktivitas' => 'Level III (Siaga)',
        ]);
    }

    private function fakeListing(): void
    {
        Http::fake([
            'magma.esdm.go.id/v1/gunung-api/tingkat-aktivitas' => Http::response(
                $this->activityHtml(),
                200,
                ['Content-Type' => 'text/html; charset=UTF-8'],
            ),
        ]);
    }

    private function activityHtml(): string
    {
        return '<table><tbody>'
            .'<tr><td rowspan="2"><a href="">Level III (Siaga)</a><span>Deskripsi tingkat aktivitas</span></td><td rowspan="2">1</td></tr>'
            .'<tr><td>Merapi - Jawa Tengah <a href="https://magma.esdm.go.id/v1/gunung-api/laporan/123?signature=fixture">Lihat laporan</a><br></td></tr>'
            .'</tbody></table>';
    }
}
