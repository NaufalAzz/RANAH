<?php

namespace Tests\Feature;

use App\Services\OsmAssemblyPointService;
use RuntimeException;
use Tests\TestCase;

class OsmAssemblyPointApiTest extends TestCase
{
    public function test_it_returns_the_two_osm_features_with_their_original_geometry_and_unverified_status(): void
    {
        $response = $this->getJson('/api/peta/titik-kumpul-osm');

        $response->assertOk()
            ->assertJsonPath('success', true)
            ->assertJsonPath('data.metadata.jumlah_fitur', 2)
            ->assertJsonPath('data.metadata.lisensi', 'ODbL-1.0')
            ->assertJsonPath('data.metadata.cakupan', 'Hanya dua fitur dalam ekspor ini; bukan inventaris seluruh Kota Padang.')
            ->assertJsonPath('data.features.0.id', 'node/13457200557')
            ->assertJsonPath('data.features.0.nama', 'Titik Kumpul dan Parkiran')
            ->assertJsonPath('data.features.0.geometri.type', 'Point')
            ->assertJsonPath('data.features.0.geometri.coordinates.0', 100.3833966)
            ->assertJsonPath('data.features.0.geometri.coordinates.1', -0.8771866)
            ->assertJsonPath('data.features.0.atribut_sumber.emergency', 'assembly_point')
            ->assertJsonPath('data.features.0.atribut_sumber.assembly_point_tsunami', null)
            ->assertJsonPath('data.features.0.atribut_sumber.operator', null)
            ->assertJsonPath('data.features.0.jenis_bencana', null)
            ->assertJsonPath('data.features.0.terverifikasi', false)
            ->assertJsonPath('data.features.0.status_verifikasi', 'Referensi OpenStreetMap — Belum Diverifikasi')
            ->assertJsonPath('data.features.1.id', 'way/1137161464')
            ->assertJsonPath('data.features.1.nama', 'Lapangan Masjid Asyiah')
            ->assertJsonPath('data.features.1.geometri.type', 'Polygon')
            ->assertJsonPath('data.features.1.terverifikasi', false)
            ->assertJsonPath('data.features.1.jenis_bencana', null);

        $features = $response->json('data.features');
        $ring = $features[1]['geometri']['coordinates'][0];
        $this->assertCount(5, $ring);
        $this->assertSame($ring[0], $ring[array_key_last($ring)]);
    }

    public function test_it_rejects_invalid_or_unclosed_geojson_polygons(): void
    {
        $path = tempnam(sys_get_temp_dir(), 'ranah-osm-');
        $this->assertNotFalse($path);

        try {
            file_put_contents($path, json_encode([
                'type' => 'FeatureCollection',
                'features' => [[
                    'type' => 'Feature',
                    'properties' => ['osm_id' => 1, 'osm_type' => 'ways_poly', 'emergency' => 'assembly_point'],
                    'geometry' => [
                        'type' => 'Polygon',
                        'coordinates' => [[[181, 0], [0, 0], [0, 1], [181, 0]]],
                    ],
                ]],
            ], JSON_THROW_ON_ERROR));

            try {
                (new OsmAssemblyPointService($path))->read();
                $this->fail('Invalid polygon coordinates must be rejected.');
            } catch (RuntimeException) {
                $this->assertTrue(true);
            }
        } finally {
            @unlink($path);
        }
    }
}
