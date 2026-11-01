<?php

namespace Tests\Feature;

use Illuminate\Http\Client\ConnectionException;
use Illuminate\Http\Client\Request;
use Illuminate\Support\Facades\Http;
use Tests\TestCase;

class InaRiskRasterAnalysisTest extends TestCase
{
    public function test_valid_tsunami_pixel_is_returned_without_an_unverified_class_while_flood_can_fail_independently(): void
    {
        Http::fake([
            'https://kspservices.big.go.id/*' => Http::response(['features' => []]),
            'https://gis.bnpb.go.id/server/rest/services/inarisk/layer_bahaya_tsunami/ImageServer/identify*' => Http::response([
                'value' => '0.0224382',
                'location' => ['x' => 10620814.0, 'y' => 617772.0, 'spatialReference' => ['wkid' => 3395]],
            ]),
            'https://gis.bnpb.go.id/server/rest/services/inarisk/layer_bahaya_banjir/ImageServer/identify*' => Http::response([
                'error' => ['code' => 500, 'message' => 'Unavailable'],
            ]),
            'https://gis.bnpb.go.id/server/rest/services/inarisk/INDEKS_BAHAYA_GEMPABUMI/ImageServer/identify*' => Http::response(['value' => 'NoData']),
        ]);

        $response = $this->postJson('/api/peta/analisis-bahaya', [
            'latitude' => 5.55,
            'longitude' => 95.32,
        ]);

        $response->assertOk()
            ->assertJsonPath('data.bahaya.tsunami.status', 'klasifikasi_belum_diverifikasi')
            ->assertJsonPath('data.bahaya.tsunami.nilai_piksel', 0.0224382)
            ->assertJsonPath('data.bahaya.tsunami.klasifikasi', null)
            ->assertJsonPath('data.bahaya.tsunami.tahun_data', null)
            ->assertJsonPath('data.bahaya.tsunami.resolusi_piksel_meter', 100)
            ->assertJsonPath('data.bahaya.tsunami.sistem_koordinat_dataset', 'EPSG:3395')
            ->assertJsonPath('data.bahaya.banjir.status', 'layanan_bermasalah')
            ->assertJsonPath('data.bahaya.letusan_gunung_api.status', 'no_data')
            ->assertJsonPath('data.bahaya.gempa_bumi.status', 'no_data');

        Http::assertSent(function (Request $request): bool {
            if (! str_contains($request->url(), 'layer_bahaya_tsunami/ImageServer/identify')) {
                return false;
            }
            parse_str((string) parse_url($request->url(), PHP_URL_QUERY), $query);
            $geometry = json_decode($query['geometry'] ?? '', true);

            return ($query['sr'] ?? null) === '4326'
                && ($query['geometryType'] ?? null) === 'esriGeometryPoint'
                && ($geometry['x'] ?? null) === 95.32
                && ($geometry['y'] ?? null) === 5.55
                && ($geometry['spatialReference']['wkid'] ?? null) === 4326;
        });
    }

    public function test_zero_is_a_valid_pixel_value_and_nodata_is_not_a_low_class(): void
    {
        Http::fake([
            'https://kspservices.big.go.id/*' => Http::response(['features' => []]),
            'https://gis.bnpb.go.id/server/rest/services/inarisk/layer_bahaya_tsunami/ImageServer/identify*' => Http::response(['value' => 0]),
            'https://gis.bnpb.go.id/server/rest/services/inarisk/layer_bahaya_banjir/ImageServer/identify*' => Http::response(['value' => 'NoData']),
            'https://gis.bnpb.go.id/server/rest/services/inarisk/INDEKS_BAHAYA_GEMPABUMI/ImageServer/identify*' => Http::response(['value' => 'NoData']),
        ]);

        $this->postJson('/api/peta/analisis-bahaya', [
            'latitude' => -0.95,
            'longitude' => 100.35,
        ])->assertOk()
            ->assertJsonPath('data.bahaya.tsunami.status', 'klasifikasi_belum_diverifikasi')
            ->assertJsonPath('data.bahaya.tsunami.nilai_piksel', 0)
            ->assertJsonPath('data.bahaya.tsunami.klasifikasi', null)
            ->assertJsonPath('data.bahaya.banjir.status', 'no_data')
            ->assertJsonPath('data.bahaya.banjir.klasifikasi', null)
            ->assertJsonPath('data.bahaya.gempa_bumi.status', 'no_data');
    }

    public function test_valid_flood_pixel_is_kept_when_tsunami_service_fails_and_krb_still_returns(): void
    {
        Http::fake([
            'https://kspservices.big.go.id/*' => Http::response([
                'features' => [[
                    'attributes' => [
                        'objectid' => 278,
                        'namobj' => 'MARAPI',
                        'indga' => 2,
                        'thterbit' => 2006,
                        'metadata' => 'IGT58_KAWASANRAWANBENCANAGUNUNGAPI_AR',
                    ],
                ]],
            ]),
            'https://gis.bnpb.go.id/server/rest/services/inarisk/layer_bahaya_tsunami/ImageServer/identify*' => Http::response([], 503),
            'https://gis.bnpb.go.id/server/rest/services/inarisk/layer_bahaya_banjir/ImageServer/identify*' => Http::response(['value' => '0.555556']),
            'https://gis.bnpb.go.id/server/rest/services/inarisk/INDEKS_BAHAYA_GEMPABUMI/ImageServer/identify*' => Http::response(['value' => 'NoData']),
        ]);

        $this->postJson('/api/peta/analisis-bahaya', [
            'latitude' => 5.55,
            'longitude' => 95.32,
        ])->assertOk()
            ->assertJsonPath('data.bahaya.tsunami.status', 'layanan_bermasalah')
            ->assertJsonPath('data.bahaya.banjir.status', 'klasifikasi_belum_diverifikasi')
            ->assertJsonPath('data.bahaya.banjir.nilai_piksel', 0.555556)
            ->assertJsonPath('data.bahaya.letusan_gunung_api.status', 'hasil_tersedia')
            ->assertJsonPath('data.bahaya.letusan_gunung_api.fitur.0.zona_krb', 'KRB II')
            ->assertJsonPath('data.bahaya.gempa_bumi.status', 'no_data');
    }

    public function test_invalid_range_and_arcgis_http_200_error_are_not_classified(): void
    {
        Http::fake([
            'https://kspservices.big.go.id/*' => Http::response(['features' => []]),
            'https://gis.bnpb.go.id/server/rest/services/inarisk/layer_bahaya_tsunami/ImageServer/identify*' => Http::response(['value' => 1.01]),
            'https://gis.bnpb.go.id/server/rest/services/inarisk/layer_bahaya_banjir/ImageServer/identify*' => Http::response(['error' => ['code' => 400, 'message' => 'bad query']]),
            'https://gis.bnpb.go.id/server/rest/services/inarisk/INDEKS_BAHAYA_GEMPABUMI/ImageServer/identify*' => Http::response(['value' => 1.01]),
        ]);

        $this->postJson('/api/peta/analisis-bahaya', [
            'latitude' => -0.95,
            'longitude' => 100.35,
        ])->assertOk()
            ->assertJsonPath('data.bahaya.tsunami.status', 'belum_dapat_ditentukan')
            ->assertJsonPath('data.bahaya.tsunami.klasifikasi', null)
            ->assertJsonPath('data.bahaya.banjir.status', 'layanan_bermasalah')
            ->assertJsonPath('data.bahaya.gempa_bumi.status', 'belum_dapat_ditentukan')
            ->assertJsonPath('data.bahaya.gempa_bumi.klasifikasi', null)
            ->assertJsonPath('data.bahaya.letusan_gunung_api.status', 'no_data');
    }

    public function test_invalid_json_and_timeout_are_isolated_to_the_affected_category(): void
    {
        Http::fake([
            'https://kspservices.big.go.id/*' => Http::response(['features' => []]),
            'https://gis.bnpb.go.id/server/rest/services/inarisk/layer_bahaya_tsunami/ImageServer/identify*' => Http::response('not json', 200),
            'https://gis.bnpb.go.id/server/rest/services/inarisk/layer_bahaya_banjir/ImageServer/identify*' => function () {
                throw new ConnectionException('simulated timeout');
            },
            'https://gis.bnpb.go.id/server/rest/services/inarisk/INDEKS_BAHAYA_GEMPABUMI/ImageServer/identify*' => Http::response('malformed JSON', 200),
        ]);

        $this->postJson('/api/peta/analisis-bahaya', [
            'latitude' => -0.95,
            'longitude' => 100.35,
        ])->assertOk()
            ->assertJsonPath('data.bahaya.tsunami.status', 'layanan_bermasalah')
            ->assertJsonPath('data.bahaya.banjir.status', 'layanan_bermasalah')
            ->assertJsonPath('data.bahaya.gempa_bumi.status', 'layanan_bermasalah')
            ->assertJsonPath('data.bahaya.letusan_gunung_api.status', 'no_data');
    }

    public function test_point_outside_raster_extents_is_not_queried_and_not_reported_safe(): void
    {
        Http::preventStrayRequests();

        $this->postJson('/api/peta/analisis-bahaya', [
            'latitude' => 30,
            'longitude' => 140,
        ])->assertOk()
            ->assertJsonPath('data.bahaya.tsunami.status', 'titik_di_luar_cakupan')
            ->assertJsonPath('data.bahaya.banjir.status', 'titik_di_luar_cakupan')
            ->assertJsonPath('data.bahaya.gempa_bumi.status', 'titik_di_luar_cakupan')
            ->assertJsonPath('data.bahaya.tsunami.klasifikasi', null)
            ->assertJsonPath('data.bahaya.banjir.klasifikasi', null);

        Http::assertNothingSent();
    }

    public function test_earthquake_index_uses_bnpb_identify_metadata_and_wgs84_xy_order(): void
    {
        Http::fake([
            'https://kspservices.big.go.id/*' => Http::response(['features' => []]),
            'https://gis.bnpb.go.id/server/rest/services/inarisk/layer_bahaya_tsunami/ImageServer/identify*' => Http::response(['value' => 'NoData']),
            'https://gis.bnpb.go.id/server/rest/services/inarisk/layer_bahaya_banjir/ImageServer/identify*' => Http::response(['value' => 'NoData']),
            'https://gis.bnpb.go.id/server/rest/services/inarisk/INDEKS_BAHAYA_GEMPABUMI/ImageServer/identify*' => Http::response([
                'value' => '0.42',
                'location' => [
                    'x' => 11183913.0,
                    'y' => -101146.0,
                    'spatialReference' => ['wkid' => 3395],
                ],
            ]),
        ]);

        $this->postJson('/api/peta/analisis-bahaya', [
            'latitude' => -0.9147,
            'longitude' => 100.4668,
        ])->assertOk()
            ->assertJsonPath('data.bahaya.gempa_bumi.status', 'klasifikasi_belum_diverifikasi')
            ->assertJsonPath('data.bahaya.gempa_bumi.dataset', 'INDEKS_BAHAYA_GEMPABUMI')
            ->assertJsonPath('data.bahaya.gempa_bumi.nilai_piksel', 0.42)
            ->assertJsonPath('data.bahaya.gempa_bumi.jenis_nilai', 'Indeks bahaya gempa ternormalisasi (0–1), bukan persentase.')
            ->assertJsonPath('data.bahaya.gempa_bumi.tipe_nilai', 'Float32')
            ->assertJsonPath('data.bahaya.gempa_bumi.klasifikasi', null)
            ->assertJsonPath('data.bahaya.gempa_bumi.tahun_data', null)
            ->assertJsonPath('data.bahaya.gempa_bumi.resolusi_piksel_meter', 100)
            ->assertJsonPath('data.bahaya.gempa_bumi.sistem_koordinat_dataset', 'EPSG:3395')
            ->assertJsonPath('data.bahaya.gempa_bumi.sumber', 'BNPB InaRISK GIS Services')
            ->assertJsonPath('data.bahaya.gempa_bumi.url_metodologi', 'https://inarisk.bnpb.go.id/metodologi')
            ->assertJsonPath('data.bahaya.gempa_bumi.metode_query', 'ArcGIS ImageServer Identify; input titik X=longitude dan Y=latitude pada EPSG:4326. Dataset menggunakan grid EPSG:3395, ukuran piksel 100 m, dan resampling default bilinear.')
            ->assertJsonPath('data.bahaya.tsunami.status', 'no_data')
            ->assertJsonPath('data.bahaya.banjir.status', 'no_data')
            ->assertJsonPath('data.bahaya.letusan_gunung_api.status', 'no_data');

        Http::assertSent(function (Request $request): bool {
            if (parse_url($request->url(), PHP_URL_PATH) !== '/server/rest/services/inarisk/INDEKS_BAHAYA_GEMPABUMI/ImageServer/identify') {
                return false;
            }

            parse_str((string) parse_url($request->url(), PHP_URL_QUERY), $query);
            $geometry = json_decode($query['geometry'] ?? '', true);

            return ($query['sr'] ?? null) === '4326'
                && ($query['geometryType'] ?? null) === 'esriGeometryPoint'
                && ($geometry['x'] ?? null) === 100.4668
                && ($geometry['y'] ?? null) === -0.9147
                && ($geometry['spatialReference']['wkid'] ?? null) === 4326;
        });
    }

    public function test_earthquake_zero_is_valid_but_nodata_is_not_classified(): void
    {
        $values = ['0', 'NoData'];
        Http::fake([
            'https://kspservices.big.go.id/*' => Http::response(['features' => []]),
            'https://gis.bnpb.go.id/server/rest/services/inarisk/layer_bahaya_tsunami/ImageServer/identify*' => Http::response(['value' => 'NoData']),
            'https://gis.bnpb.go.id/server/rest/services/inarisk/layer_bahaya_banjir/ImageServer/identify*' => Http::response(['value' => 'NoData']),
            'https://gis.bnpb.go.id/server/rest/services/inarisk/INDEKS_BAHAYA_GEMPABUMI/ImageServer/identify*' => function () use (&$values) {
                return Http::response(['value' => array_shift($values)]);
            },
        ]);

        $this->postJson('/api/peta/analisis-bahaya', [
            'latitude' => -0.9147,
            'longitude' => 100.4668,
        ])->assertOk()
            ->assertJsonPath('data.bahaya.gempa_bumi.status', 'klasifikasi_belum_diverifikasi')
            ->assertJsonPath('data.bahaya.gempa_bumi.nilai_piksel', 0)
            ->assertJsonPath('data.bahaya.gempa_bumi.klasifikasi', null);

        $this->postJson('/api/peta/analisis-bahaya', [
            'latitude' => -0.9147,
            'longitude' => 100.4668,
        ])->assertOk()
            ->assertJsonPath('data.bahaya.gempa_bumi.status', 'no_data')
            ->assertJsonPath('data.bahaya.gempa_bumi.nilai_piksel', null)
            ->assertJsonPath('data.bahaya.gempa_bumi.klasifikasi', null);
    }

    public function test_earthquake_failure_does_not_remove_other_hazard_results(): void
    {
        Http::fake([
            'https://kspservices.big.go.id/*' => Http::response(['features' => [
                ['attributes' => [
                    'objectid' => 278,
                    'namobj' => 'MARAPI',
                    'indga' => 2,
                    'thterbit' => 2006,
                    'metadata' => 'IGT58_KAWASANRAWANBENCANAGUNUNGAPI_AR',
                ]],
            ]]),
            'https://gis.bnpb.go.id/server/rest/services/inarisk/layer_bahaya_tsunami/ImageServer/identify*' => Http::response(['value' => 'NoData']),
            'https://gis.bnpb.go.id/server/rest/services/inarisk/layer_bahaya_banjir/ImageServer/identify*' => Http::response(['value' => 'NoData']),
            'https://gis.bnpb.go.id/server/rest/services/inarisk/INDEKS_BAHAYA_GEMPABUMI/ImageServer/identify*' => Http::response(['error' => ['code' => 503, 'message' => 'Unavailable']]),
        ]);

        $this->postJson('/api/peta/analisis-bahaya', [
            'latitude' => -0.9147,
            'longitude' => 100.4668,
        ])->assertOk()
            ->assertJsonPath('data.bahaya.gempa_bumi.status', 'layanan_bermasalah')
            ->assertJsonPath('data.bahaya.gempa_bumi.klasifikasi', null)
            ->assertJsonPath('data.bahaya.tsunami.status', 'no_data')
            ->assertJsonPath('data.bahaya.banjir.status', 'no_data')
            ->assertJsonPath('data.bahaya.letusan_gunung_api.status', 'hasil_tersedia')
            ->assertJsonPath('data.bahaya.letusan_gunung_api.fitur.0.zona_krb', 'KRB II');
    }

    public function test_earthquake_timeout_is_isolated_from_other_categories(): void
    {
        Http::fake([
            'https://kspservices.big.go.id/*' => Http::response(['features' => []]),
            'https://gis.bnpb.go.id/server/rest/services/inarisk/layer_bahaya_tsunami/ImageServer/identify*' => Http::response(['value' => 'NoData']),
            'https://gis.bnpb.go.id/server/rest/services/inarisk/layer_bahaya_banjir/ImageServer/identify*' => Http::response(['value' => 'NoData']),
            'https://gis.bnpb.go.id/server/rest/services/inarisk/INDEKS_BAHAYA_GEMPABUMI/ImageServer/identify*' => function () {
                throw new ConnectionException('simulated earthquake identify timeout');
            },
        ]);

        $this->postJson('/api/peta/analisis-bahaya', [
            'latitude' => -0.9147,
            'longitude' => 100.4668,
        ])->assertOk()
            ->assertJsonPath('data.bahaya.gempa_bumi.status', 'layanan_bermasalah')
            ->assertJsonPath('data.bahaya.tsunami.status', 'no_data')
            ->assertJsonPath('data.bahaya.banjir.status', 'no_data')
            ->assertJsonPath('data.bahaya.letusan_gunung_api.status', 'no_data');
    }

    public function test_earthquake_http_503_is_isolated_from_other_categories(): void
    {
        Http::fake([
            'https://kspservices.big.go.id/*' => Http::response(['features' => []]),
            'https://gis.bnpb.go.id/server/rest/services/inarisk/layer_bahaya_tsunami/ImageServer/identify*' => Http::response(['value' => 'NoData']),
            'https://gis.bnpb.go.id/server/rest/services/inarisk/layer_bahaya_banjir/ImageServer/identify*' => Http::response(['value' => 'NoData']),
            'https://gis.bnpb.go.id/server/rest/services/inarisk/INDEKS_BAHAYA_GEMPABUMI/ImageServer/identify*' => Http::response(['unavailable' => true], 503),
        ]);

        $this->postJson('/api/peta/analisis-bahaya', [
            'latitude' => -0.9147,
            'longitude' => 100.4668,
        ])->assertOk()
            ->assertJsonPath('data.bahaya.gempa_bumi.status', 'layanan_bermasalah')
            ->assertJsonPath('data.bahaya.tsunami.status', 'no_data')
            ->assertJsonPath('data.bahaya.banjir.status', 'no_data');
    }

    public function test_shared_analysis_endpoint_retains_its_rate_limit(): void
    {
        Http::fake([
            'https://kspservices.big.go.id/*' => Http::response(['features' => []]),
            'https://gis.bnpb.go.id/*' => Http::response(['value' => 'NoData']),
        ]);

        for ($attempt = 0; $attempt < 5; $attempt++) {
            $this->postJson('/api/peta/analisis-bahaya', [
                'latitude' => -0.95,
                'longitude' => 100.35,
            ])->assertOk();
        }

        $this->postJson('/api/peta/analisis-bahaya', [
            'latitude' => -0.95,
            'longitude' => 100.35,
        ])->assertTooManyRequests();
    }
}
