<?php

namespace App\Services;

use Illuminate\Http\Client\ConnectionException;
use Illuminate\Support\Facades\Http;
use UnexpectedValueException;

class OpenRouteServiceRoutingService implements FootWalkingRoutingProvider
{
    private const string URL = 'https://api.openrouteservice.org/v2/directions/foot-walking/geojson';

    /** @return array<string, mixed> */
    public function route(
        float $originLatitude,
        float $originLongitude,
        array $destination,
    ): array {
        $apiKey = trim((string) config('services.openrouteservice.api_key', ''));
        if ($apiKey === '') {
            throw new RouteSimulationException(
                'ors_not_configured',
                'Routing pejalan kaki ORS belum dikonfigurasi pada server.',
            );
        }

        $coordinates = $destination['geometri']['coordinates'] ?? null;
        if (($destination['geometri']['type'] ?? null) !== 'Point'
            || ! is_array($coordinates)
            || count($coordinates) < 2
            || ! is_numeric($coordinates[0] ?? null)
            || ! is_numeric($coordinates[1] ?? null)) {
            throw new RouteSimulationException(
                'destination_not_routable',
                'Rute hanya tersedia untuk fitur Point yang memiliki koordinat valid.',
                422,
            );
        }

        $destinationLongitude = (float) $coordinates[0];
        $destinationLatitude = (float) $coordinates[1];
        if (! is_finite($destinationLongitude) || ! is_finite($destinationLatitude)
            || $destinationLongitude < -180 || $destinationLongitude > 180
            || $destinationLatitude < -90 || $destinationLatitude > 90) {
            throw new RouteSimulationException(
                'destination_not_routable',
                'Koordinat tujuan dari dataset tidak valid.',
                422,
            );
        }

        try {
            $response = Http::withHeaders([
                'Authorization' => $apiKey,
                'Content-Type' => 'application/json',
                'Accept' => 'application/geo+json, application/json',
            ])->connectTimeout(5)->timeout(15)->post(
                (string) config('services.openrouteservice.foot_walking_url', self::URL),
                [
                    'coordinates' => [
                        [$originLongitude, $originLatitude],
                        [$destinationLongitude, $destinationLatitude],
                    ],
                    'instructions' => false,
                    'units' => 'm',
                ],
            );
        } catch (ConnectionException $exception) {
            throw new RouteSimulationException(
                'ors_connection_failure',
                'Layanan routing sementara tidak dapat dihubungi.',
                previous: $exception,
            );
        }

        if ($response->status() === 429) {
            throw new RouteSimulationException(
                'ors_rate_limited',
                'Layanan routing sedang membatasi permintaan. Coba lagi nanti.',
                503,
            );
        }
        if ($response->status() === 404) {
            throw new RouteSimulationException(
                'route_not_found',
                'Jaringan jalan tidak menyediakan rute pejalan kaki untuk pasangan lokasi ini.',
                422,
            );
        }
        if (! $response->successful()) {
            throw new RouteSimulationException(
                'ors_service_failure',
                'Layanan routing sementara tidak dapat memberikan rute.',
            );
        }

        $payload = $response->json();
        if (! is_array($payload) || ! is_array($payload['features'] ?? null)) {
            throw new RouteSimulationException(
                'invalid_ors_response',
                'Respons routing tidak dapat divalidasi.',
            );
        }
        $feature = $payload['features'][0] ?? null;
        if (! is_array($feature)) {
            throw new RouteSimulationException(
                'route_not_found',
                'Layanan routing tidak menemukan rute untuk lokasi ini.',
                422,
            );
        }

        try {
            $line = $this->validateLine($feature['geometry'] ?? null);
            $distance = $feature['properties']['summary']['distance'] ?? null;
            if (! is_numeric($distance) || ! is_finite((float) $distance) || (float) $distance <= 0) {
                throw new UnexpectedValueException('Invalid route distance.');
            }
        } catch (UnexpectedValueException $exception) {
            throw new RouteSimulationException(
                'invalid_ors_response',
                'Geometri atau jarak routing tidak valid.',
                previous: $exception,
            );
        }

        return [
            'geometri' => ['type' => 'LineString', 'coordinates' => $line],
            'jarak_meter' => (float) $distance,
            'jarak_km' => round(((float) $distance) / 1000, 2),
            'durasi_detik' => is_numeric($feature['properties']['summary']['duration'] ?? null)
                ? (float) $feature['properties']['summary']['duration']
                : null,
            'sumber_jaringan' => 'OpenStreetMap melalui openrouteservice.org',
            'atribusi' => '© OpenStreetMap contributors',
            'url_atribusi' => 'https://www.openstreetmap.org/copyright',
            'metode' => 'OpenRouteService profile foot-walking; jarak mengikuti jaringan jalan yang tersedia.',
            'peringatan' => 'Simulasi Jalur Menuju Titik Kumpul — Bukan Jalur Evakuasi Resmi. Jalur mengikuti data jalan OpenStreetMap; keamanan jalur dan status tujuan belum diverifikasi.',
        ];
    }

    /** @return list<array{float, float}> GeoJSON order: longitude, latitude. */
    private function validateLine(mixed $geometry): array
    {
        if (! is_array($geometry)
            || ($geometry['type'] ?? null) !== 'LineString'
            || ! is_array($geometry['coordinates'] ?? null)
            || count($geometry['coordinates']) < 2) {
            throw new UnexpectedValueException('ORS did not return a LineString.');
        }

        $line = [];
        foreach ($geometry['coordinates'] as $position) {
            if (! is_array($position) || count($position) < 2
                || ! is_numeric($position[0] ?? null) || ! is_numeric($position[1] ?? null)) {
                throw new UnexpectedValueException('ORS LineString has invalid positions.');
            }
            $longitude = (float) $position[0];
            $latitude = (float) $position[1];
            if (! is_finite($longitude) || ! is_finite($latitude)
                || $longitude < -180 || $longitude > 180
                || $latitude < -90 || $latitude > 90) {
                throw new UnexpectedValueException('ORS LineString position is out of range.');
            }
            $line[] = [$longitude, $latitude];
        }

        return $line;
    }
}
