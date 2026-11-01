<?php

namespace Tests\Feature;

use Illuminate\Http\Client\Request;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;
use Tests\TestCase;

class HazardSpatialAnalysisTest extends TestCase
{
    public function test_point_intersects_returns_every_matching_krb_feature_and_source_metadata(): void
    {
        Http::fake([
            'https://kspservices.big.go.id/*' => Http::response([
                'features' => [
                    $this->feature(277, 'MARAPI', 1, 2006),
                    $this->feature(278, 'MARAPI', 2, 2006),
                    $this->feature(991, 'VOLCANO B', 3, 2014),
                ],
            ]),
            'https://gis.bnpb.go.id/*' => Http::response(['value' => 'NoData']),
        ]);

        $response = $this->postJson('/api/peta/analisis-bahaya', [
            'latitude' => -0.381234567,
            'longitude' => 100.473456789,
        ]);

        $response->assertOk()
            ->assertJsonPath('data.sistem_koordinat', 'EPSG:4326')
            ->assertJsonPath('data.bahaya.letusan_gunung_api.status', 'hasil_tersedia')
            ->assertJsonPath('data.bahaya.letusan_gunung_api.fitur.0.nama_gunung', 'MARAPI')
            ->assertJsonPath('data.bahaya.letusan_gunung_api.fitur.0.zona_krb', 'KRB I')
            ->assertJsonPath('data.bahaya.letusan_gunung_api.fitur.0.tahun_peta', 2006)
            ->assertJsonPath('data.bahaya.letusan_gunung_api.fitur.2.id_fitur_sumber', 991)
            ->assertJsonPath('data.bahaya.letusan_gunung_api.sumber', 'Badan Informasi Geospasial (BIG), Satu Peta')
            ->assertJsonPath('data.bahaya.tsunami.status', 'no_data')
            ->assertJsonPath('data.bahaya.banjir.status', 'no_data')
            ->assertJsonPath('data.bahaya.gempa_bumi.status', 'no_data');

        Http::assertSent(function (Request $request): bool {
            $query = [];
            parse_str((string) parse_url($request->url(), PHP_URL_QUERY), $query);
            $geometry = json_decode($query['geometry'] ?? '', true);

            return parse_url($request->url(), PHP_URL_PATH) === '/satupeta/rest/services/PUBLIK/SUMBER_DAYA_ALAM_DAN_LINGKUNGAN/MapServer/11/query'
                && ($query['spatialRel'] ?? null) === 'esriSpatialRelIntersects'
                && ($query['geometryType'] ?? null) === 'esriGeometryPoint'
                && ($query['inSR'] ?? null) === '4326'
                && ($geometry['x'] ?? null) === 100.473456789
                && ($geometry['y'] ?? null) === -0.381234567;
        });
    }

    public function test_no_intersection_is_no_data_and_never_reported_as_safe(): void
    {
        Http::fake([
            'https://kspservices.big.go.id/*' => Http::response(['features' => []]),
            'https://gis.bnpb.go.id/*' => Http::response(['value' => 'NoData']),
        ]);

        $response = $this->postJson('/api/peta/analisis-bahaya', [
            'latitude' => -0.9147,
            'longitude' => 100.4668,
        ]);

        $response->assertOk()
            ->assertJsonPath('data.bahaya.letusan_gunung_api.status', 'no_data')
            ->assertJsonPath('data.bahaya.letusan_gunung_api.fitur', [])
            ->assertJsonPath(
                'data.bahaya.letusan_gunung_api.penjelasan',
                'Tidak ditemukan fitur KRB yang beririsan pada layer BIG ini. Data yang tidak ditemukan bukan bukti bahwa lokasi aman.',
            );
    }

    public function test_coordinates_outside_the_published_layer_extent_do_not_call_big(): void
    {
        Http::preventStrayRequests();

        $this->postJson('/api/peta/analisis-bahaya', [
            'latitude' => 30.0,
            'longitude' => 140.0,
        ])->assertOk()
            ->assertJsonPath('data.bahaya.letusan_gunung_api.status', 'di_luar_cakupan_layer')
            ->assertJsonPath('data.bahaya.letusan_gunung_api.fitur', []);

        Http::assertNothingSent();
    }

    public function test_invalid_coordinates_are_rejected_before_any_external_request(): void
    {
        Http::preventStrayRequests();

        $this->postJson('/api/peta/analisis-bahaya', [
            'latitude' => 91,
            'longitude' => 100,
        ])->assertUnprocessable()
            ->assertJsonValidationErrors(['latitude']);

        Http::assertNothingSent();
    }

    public function test_upstream_failure_returns_neutral_service_error_without_logging_coordinates(): void
    {
        Http::fake([
            'https://kspservices.big.go.id/*' => Http::response([], 503),
            'https://gis.bnpb.go.id/*' => Http::response(['value' => 'NoData']),
        ]);
        Log::spy();

        $this->postJson('/api/peta/analisis-bahaya', [
            'latitude' => -0.381234567,
            'longitude' => 100.473456789,
        ])->assertOk()
            ->assertJsonPath('data.bahaya.letusan_gunung_api.status', 'layanan_gagal')
            ->assertJsonPath('data.bahaya.letusan_gunung_api.fitur', []);

        Log::shouldNotHaveReceived('info');
        Log::shouldNotHaveReceived('warning');
    }

    public function test_malformed_feature_makes_the_analysis_indeterminate(): void
    {
        Http::fake([
            'https://kspservices.big.go.id/*' => Http::response([
                'features' => [['attributes' => ['objectid' => 2, 'namobj' => 'Unknown', 'indga' => 9]]],
            ]),
            'https://gis.bnpb.go.id/*' => Http::response(['value' => 'NoData']),
        ]);

        $this->postJson('/api/peta/analisis-bahaya', [
            'latitude' => -0.381,
            'longitude' => 100.473,
        ])->assertOk()
            ->assertJsonPath('data.bahaya.letusan_gunung_api.status', 'analisis_tidak_dapat_ditentukan')
            ->assertJsonPath('data.bahaya.letusan_gunung_api.fitur', []);
    }

    /** @return array{attributes: array<string, int|string>} */
    private function feature(int $id, string $name, int $zone, int $year): array
    {
        return ['attributes' => [
            'objectid' => $id,
            'namobj' => $name,
            'indga' => $zone,
            'thterbit' => $year,
            'metadata' => 'IGT58_KAWASANRAWANBENCANAGUNUNGAPI_AR',
        ]];
    }
}
