<?php

namespace Tests\Feature;

use App\Services\ValhallaRoutingService;
use Illuminate\Http\Client\ConnectionException;
use Illuminate\Http\Client\Request;
use Illuminate\Support\Facades\Http;
use Tests\TestCase;

class RouteSimulationApiTest extends TestCase
{
    private const string ENDPOINT = 'https://api.openrouteservice.org/v2/directions/foot-walking/geojson';

    private const string DESTINATION = 'node/13457200557';

    public function test_point_route_uses_lon_lat_order_and_returns_valid_geojson_distance_and_disclaimers(): void
    {
        $this->enableOrs();
        Http::fake([self::ENDPOINT => Http::response($this->routePayload(), 200)]);

        $response = $this->postJson('/api/peta/rute-simulasi', [
            'latitude' => -0.8701,
            'longitude' => 100.39,
            'destination_id' => self::DESTINATION,
        ]);

        $response->assertOk()
            ->assertJsonPath('success', true)
            ->assertJsonPath('data.geometri.type', 'LineString')
            ->assertJsonPath('data.geometri.coordinates.0.0', 100.39)
            ->assertJsonPath('data.geometri.coordinates.0.1', -0.8701)
            ->assertJsonPath('data.jarak_meter', 1234.5)
            ->assertJsonPath('data.jarak_km', 1.23)
            ->assertJsonPath('data.tujuan.id', self::DESTINATION)
            ->assertJsonPath('data.tujuan.status_verifikasi', 'Referensi OpenStreetMap — Belum Diverifikasi')
            ->assertJsonPath('data.sumber_jaringan', 'OpenStreetMap melalui openrouteservice.org')
            ->assertJsonPath('data.peringatan', 'Simulasi Jalur Menuju Titik Kumpul — Bukan Jalur Evakuasi Resmi. Jalur mengikuti data jalan OpenStreetMap; keamanan jalur dan status tujuan belum diverifikasi.');

        Http::assertSent(function (Request $request): bool {
            $json = $request->data();

            return $request->url() === self::ENDPOINT
                && $request->header('Authorization')[0] === 'fixture-server-key'
                && ($json['coordinates'] ?? null) === [
                    [100.39, -0.8701],
                    [100.3833966, -0.8771866],
                ]
                && ($json['units'] ?? null) === 'm';
        });
    }

    public function test_polygon_cannot_be_used_as_an_entrance_and_does_not_call_ors(): void
    {
        $this->enableOrs();
        Http::preventStrayRequests();

        $this->postJson('/api/peta/rute-simulasi', [
            'latitude' => -0.8701,
            'longitude' => 100.39,
            'destination_id' => 'way/1137161464',
        ])->assertUnprocessable()
            ->assertJsonPath('code', 'polygon_access_not_available');

        Http::assertNothingSent();
    }

    public function test_missing_server_key_disables_routing_without_external_request(): void
    {
        config(['services.routing.provider' => 'ors']);
        config(['services.openrouteservice.api_key' => null]);
        Http::preventStrayRequests();

        $this->postJson('/api/peta/rute-simulasi', [
            'latitude' => -0.8701,
            'longitude' => 100.39,
            'destination_id' => self::DESTINATION,
        ])->assertStatus(503)
            ->assertJsonPath('code', 'ors_not_configured');

        Http::assertNothingSent();
    }

    public function test_missing_osm_destination_is_rejected(): void
    {
        Http::preventStrayRequests();

        $this->postJson('/api/peta/rute-simulasi', [
            'latitude' => -0.8701,
            'longitude' => 100.39,
            'destination_id' => 'node/999999999999',
        ])->assertNotFound()
            ->assertJsonPath('code', 'destination_not_found');

        Http::assertNothingSent();
    }

    public function test_invalid_origin_is_rejected_before_calling_ors(): void
    {
        $this->enableOrs();
        Http::preventStrayRequests();

        $this->postJson('/api/peta/rute-simulasi', [
            'latitude' => 91,
            'longitude' => 100.39,
            'destination_id' => self::DESTINATION,
        ])->assertUnprocessable()
            ->assertJsonValidationErrors(['latitude']);

        Http::assertNothingSent();
    }

    public function test_no_route_from_ors_is_returned_as_a_clear_no_route_result(): void
    {
        $this->enableOrs();
        Http::fake([self::ENDPOINT => Http::response(['error' => ['code' => 2010]], 404)]);

        $this->postJson('/api/peta/rute-simulasi', [
            'latitude' => -0.8701,
            'longitude' => 100.39,
            'destination_id' => self::DESTINATION,
        ])->assertUnprocessable()
            ->assertJsonPath('code', 'route_not_found');
    }

    public function test_invalid_linestring_and_invalid_distance_never_return_a_route(): void
    {
        $this->enableOrs();
        foreach ([
            ['features' => [['geometry' => ['type' => 'Polygon', 'coordinates' => []], 'properties' => ['summary' => ['distance' => 12]]]]],
            ['features' => [['geometry' => ['type' => 'LineString', 'coordinates' => [[100.3, -0.8], [100.4, -0.7]]], 'properties' => ['summary' => ['distance' => -1]]]]],
        ] as $payload) {
            Http::fake([self::ENDPOINT => Http::response($payload, 200)]);
            $this->postJson('/api/peta/rute-simulasi', [
                'latitude' => -0.8701,
                'longitude' => 100.39,
                'destination_id' => self::DESTINATION,
            ])->assertStatus(503)
                ->assertJsonPath('code', 'invalid_ors_response');
        }
    }

    public function test_ors_timeout_and_rate_limit_are_reported_without_retry(): void
    {
        $this->enableOrs();
        $requests = 0;
        Http::fake([self::ENDPOINT => function () use (&$requests) {
            $requests++;
            if ($requests === 1) {
                throw new ConnectionException('cURL error 28: Operation timed out');
            }

            return Http::response([], 429);
        }]);
        $this->postJson('/api/peta/rute-simulasi', [
            'latitude' => -0.8701,
            'longitude' => 100.39,
            'destination_id' => self::DESTINATION,
        ])->assertStatus(503)
            ->assertJsonPath('code', 'ors_connection_failure');
        $this->assertSame(1, $requests, 'The timeout is not retried.');

        $this->postJson('/api/peta/rute-simulasi', [
            'latitude' => -0.8701,
            'longitude' => 100.39,
            'destination_id' => self::DESTINATION,
        ])->assertStatus(503)
            ->assertJsonPath('code', 'ors_rate_limited');
        $this->assertSame(2, $requests, 'Each user-triggered call is sent once.');
        Http::assertSentCount(1);
    }

    public function test_valhalla_provider_normalizes_polyline6_distance_and_duration(): void
    {
        config([
            'services.routing.provider' => 'valhalla',
            'services.routing.valhalla_base_url' => 'https://valhalla1.openstreetmap.de',
        ]);
        $shape = $this->encodePolyline6([
            [-0.8701, 100.39],
            [-0.874, 100.387],
            [-0.8771866, 100.3833966],
        ]);
        Http::fake(['https://valhalla1.openstreetmap.de/route' => Http::response([
            'trip' => [
                'status' => 0,
                'summary' => ['length' => 3.439, 'time' => 2585.046],
                'legs' => [['shape' => $shape]],
            ],
        ], 200)]);

        $response = $this->postJson('/api/peta/rute-simulasi', [
            'latitude' => -0.8701,
            'longitude' => 100.39,
            'destination_id' => self::DESTINATION,
        ]);

        $response->assertOk()
            ->assertJsonPath('data.geometri.type', 'LineString')
            ->assertJsonPath('data.geometri.coordinates.0.0', 100.39)
            ->assertJsonPath('data.geometri.coordinates.0.1', -0.8701)
            ->assertJsonPath('data.geometri.coordinates.2.0', 100.383397)
            ->assertJsonPath('data.geometri.coordinates.2.1', -0.877187)
            ->assertJsonPath('data.jarak_meter', 3439)
            ->assertJsonPath('data.jarak_km', 3.44)
            ->assertJsonPath('data.durasi_detik', 2585.046)
            ->assertJsonPath('data.sumber_jaringan', 'OpenStreetMap melalui Valhalla demo');

        Http::assertSent(function (Request $request): bool {
            return $request->url() === 'https://valhalla1.openstreetmap.de/route'
                && ($request->header('X-Client-Id')[0] ?? null) === 'RANAH-AcademicPrototype/1.0'
                && ($request->data()['costing'] ?? null) === 'pedestrian'
                && ($request->data()['units'] ?? null) === 'kilometers'
                && ($request->data()['locations'] ?? null) === [
                    ['lat' => -0.8701, 'lon' => 100.39],
                    ['lat' => -0.8771866, 'lon' => 100.3833966],
                ];
        });
    }

    public function test_polyline6_decoder_preserves_precision_and_geojson_axis_order(): void
    {
        $points = [
            [-0.8701, 100.39],
            [-0.874, 100.387],
        ];

        $this->assertSame([
            [100.39, -0.8701],
            [100.387, -0.874],
        ], ValhallaRoutingService::decodePolyline6($this->encodePolyline6($points)));
        $this->expectException(\UnexpectedValueException::class);
        ValhallaRoutingService::decodePolyline6('~');
    }

    public function test_sanitized_powershell_live_response_fixture_decodes(): void
    {
        $fixture = json_decode(
            file_get_contents(base_path('tests/Fixtures/valhalla_public_route_response.json')),
            true,
            512,
            JSON_THROW_ON_ERROR,
        );
        $trip = $fixture['trip'];
        $this->assertSame(0, $trip['status']);
        $this->assertSame(3.439, $trip['summary']['length']);
        $this->assertSame(2585.046, $trip['summary']['time']);
        $line = ValhallaRoutingService::decodePolyline6($trip['legs'][0]['shape']);
        $this->assertGreaterThan(2, count($line));
        foreach ($line as [$longitude, $latitude]) {
            $this->assertGreaterThanOrEqual(-180, $longitude);
            $this->assertLessThanOrEqual(180, $longitude);
            $this->assertGreaterThanOrEqual(-90, $latitude);
            $this->assertLessThanOrEqual(90, $latitude);
        }
    }

    public function test_valhalla_rate_limit_and_invalid_shape_are_handled(): void
    {
        config(['services.routing.provider' => 'valhalla']);
        Http::fake(['https://valhalla1.openstreetmap.de/route' => Http::response([], 429)]);
        $this->postJson('/api/peta/rute-simulasi', [
            'latitude' => -0.8701,
            'longitude' => 100.39,
            'destination_id' => self::DESTINATION,
        ])->assertStatus(503)->assertJsonPath('code', 'valhalla_rate_limited');

    }

    public function test_valhalla_invalid_shape_is_rejected(): void
    {
        config(['services.routing.provider' => 'valhalla']);
        Http::fake(['https://valhalla1.openstreetmap.de/route' => Http::response([
            'trip' => ['status' => 0, 'summary' => ['length' => 1, 'time' => 100], 'legs' => [['shape' => 'bad']]],
        ], 200)]);
        $this->postJson('/api/peta/rute-simulasi', [
            'latitude' => -0.8701,
            'longitude' => 100.39,
            'destination_id' => self::DESTINATION,
        ])->assertStatus(503)->assertJsonPath('code', 'invalid_valhalla_response');
    }

    /** @param list<array{float, float}> $latLon */
    private function encodePolyline6(array $latLon): string
    {
        $encoded = '';
        $previousLat = 0;
        $previousLon = 0;
        foreach ($latLon as [$latitude, $longitude]) {
            $lat = (int) round($latitude * 1_000_000);
            $lon = (int) round($longitude * 1_000_000);
            $encoded .= $this->encodePolylineValue($lat - $previousLat);
            $encoded .= $this->encodePolylineValue($lon - $previousLon);
            $previousLat = $lat;
            $previousLon = $lon;
        }

        return $encoded;
    }

    private function encodePolylineValue(int $value): string
    {
        $value = $value < 0 ? ~($value << 1) : ($value << 1);
        $encoded = '';
        while ($value >= 0x20) {
            $encoded .= chr((0x20 | ($value & 0x1F)) + 63);
            $value >>= 5;
        }

        return $encoded.chr($value + 63);
    }

    /** @return array<string, mixed> */
    private function routePayload(): array
    {
        return [
            'features' => [[
                'geometry' => [
                    'type' => 'LineString',
                    'coordinates' => [[100.39, -0.8701], [100.387, -0.874], [100.3833966, -0.8771866]],
                ],
                'properties' => ['summary' => ['distance' => 1234.5]],
            ]],
        ];
    }

    private function enableOrs(): void
    {
        config(['services.routing.provider' => 'ors']);
        config(['services.openrouteservice.api_key' => 'fixture-server-key']);
    }
}
