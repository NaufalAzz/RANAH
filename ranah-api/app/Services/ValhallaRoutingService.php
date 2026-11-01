<?php

namespace App\Services;

use Illuminate\Http\Client\ConnectionException;
use Illuminate\Support\Facades\Http;
use UnexpectedValueException;

class ValhallaRoutingService implements FootWalkingRoutingProvider
{
    private const string HOST = 'valhalla1.openstreetmap.de';

    /** @param array<string, mixed> $destination
     * @return array<string, mixed>
     */
    public function route(float $originLatitude, float $originLongitude, array $destination): array
    {
        $point = $destination['geometri']['coordinates'] ?? null;
        if (($destination['geometri']['type'] ?? null) !== 'Point'
            || ! is_array($point)
            || count($point) < 2
            || ! is_numeric($point[0] ?? null)
            || ! is_numeric($point[1] ?? null)) {
            throw new RouteSimulationException(
                'destination_not_routable',
                'Rute hanya tersedia untuk fitur Point yang memiliki koordinat valid.',
                422,
            );
        }

        $destinationLongitude = (float) $point[0];
        $destinationLatitude = (float) $point[1];
        if (! $this->validPosition($originLatitude, $originLongitude)
            || ! $this->validPosition($destinationLatitude, $destinationLongitude)) {
            throw new RouteSimulationException(
                'destination_not_routable',
                'Koordinat asal atau tujuan tidak valid.',
                422,
            );
        }

        $baseUrl = rtrim((string) config('services.routing.valhalla_base_url'), '/');
        $baseUri = parse_url($baseUrl);
        if (! is_array($baseUri)
            || ($baseUri['scheme'] ?? null) !== 'https'
            || strtolower((string) ($baseUri['host'] ?? '')) !== self::HOST
            || isset($baseUri['user'])
            || isset($baseUri['pass'])) {
            throw new RouteSimulationException(
                'valhalla_not_configured',
                'Endpoint Valhalla server tidak valid atau belum dikonfigurasi.',
            );
        }

        try {
            $response = Http::withHeaders([
                'X-Client-Id' => (string) config('services.routing.valhalla_client_id', 'RANAH-AcademicPrototype/1.0'),
                'Accept' => 'application/json',
                'Content-Type' => 'application/json',
            ])->connectTimeout(5)->timeout(20)->post($baseUrl.'/route', [
                'locations' => [
                    ['lat' => $originLatitude, 'lon' => $originLongitude],
                    ['lat' => $destinationLatitude, 'lon' => $destinationLongitude],
                ],
                'costing' => 'pedestrian',
                'units' => 'kilometers',
                'directions_type' => 'none',
            ]);
        } catch (ConnectionException $exception) {
            throw new RouteSimulationException(
                'valhalla_connection_failure',
                'Layanan routing sementara tidak dapat dihubungi.',
                previous: $exception,
            );
        }

        if ($response->status() === 429) {
            throw new RouteSimulationException(
                'valhalla_rate_limited',
                'Layanan routing sedang membatasi permintaan. Coba lagi nanti.',
            );
        }
        if ($response->status() === 404 || $response->status() === 422) {
            throw new RouteSimulationException(
                'route_not_found',
                'Jaringan jalan tidak menyediakan rute pejalan kaki untuk pasangan lokasi ini.',
                422,
            );
        }
        if ($response->status() === 400) {
            throw new RouteSimulationException(
                'route_not_found',
                'Jaringan jalan tidak menyediakan rute pejalan kaki untuk pasangan lokasi ini.',
                422,
            );
        }
        if (! $response->successful()) {
            throw new RouteSimulationException(
                'valhalla_service_failure',
                'Layanan routing sementara tidak dapat memberikan rute.',
            );
        }

        $payload = $response->json();
        if (! is_array($payload) || ! is_array($payload['trip'] ?? null)) {
            throw new RouteSimulationException(
                'invalid_valhalla_response',
                'Respons routing tidak dapat divalidasi.',
            );
        }

        $trip = $payload['trip'];
        if (isset($trip['status']) && (int) $trip['status'] !== 0) {
            throw new RouteSimulationException(
                'route_not_found',
                'Layanan routing tidak menemukan jalur pejalan kaki untuk lokasi ini.',
                422,
            );
        }

        try {
            $summary = $trip['summary'] ?? null;
            $distanceKm = is_array($summary) ? ($summary['length'] ?? null) : null;
            $durationSeconds = is_array($summary) ? ($summary['time'] ?? null) : null;
            if (! is_numeric($distanceKm) || ! is_finite((float) $distanceKm) || (float) $distanceKm <= 0
                || ! is_numeric($durationSeconds) || ! is_finite((float) $durationSeconds) || (float) $durationSeconds < 0) {
                throw new UnexpectedValueException('Invalid Valhalla summary.');
            }

            $legs = $trip['legs'] ?? null;
            if (! is_array($legs) || $legs === []) {
                throw new UnexpectedValueException('Valhalla response has no legs.');
            }
            $line = [];
            foreach ($legs as $leg) {
                $shape = is_array($leg) ? ($leg['shape'] ?? null) : null;
                if (! is_string($shape) || $shape === '') {
                    throw new UnexpectedValueException('Valhalla leg has no encoded polyline6.');
                }
                foreach (self::decodePolyline6($shape) as $position) {
                    $last = $line === [] ? null : $line[array_key_last($line)];
                    if ($last !== $position) {
                        $line[] = $position;
                    }
                }
            }
            if (count($line) < 2) {
                throw new UnexpectedValueException('Valhalla route has fewer than two points.');
            }
        } catch (UnexpectedValueException $exception) {
            throw new RouteSimulationException(
                'invalid_valhalla_response',
                'Geometri atau ringkasan routing tidak valid.',
                previous: $exception,
            );
        }

        return [
            'geometri' => ['type' => 'LineString', 'coordinates' => $line],
            'jarak_meter' => (float) $distanceKm * 1000,
            'jarak_km' => round((float) $distanceKm, 2),
            'durasi_detik' => (float) $durationSeconds,
            'sumber_jaringan' => 'OpenStreetMap melalui Valhalla demo',
            'atribusi' => '© OpenStreetMap contributors',
            'url_atribusi' => 'https://www.openstreetmap.org/copyright',
            'metode' => 'Valhalla costing pedestrian; jarak mengikuti jaringan jalan yang tersedia.',
            'peringatan' => 'Simulasi Jalur Menuju Titik Kumpul — Bukan Jalur Evakuasi Resmi. Jalur mengikuti data jalan OpenStreetMap; keamanan jalur dan status tujuan belum diverifikasi.',
        ];
    }

    /** Decode Valhalla's encoded polyline6 to GeoJSON positions [longitude, latitude].
     * @return list<array{float, float}>
     */
    public static function decodePolyline6(string $encoded): array
    {
        if ($encoded === '') {
            throw new UnexpectedValueException('Encoded polyline is empty.');
        }

        $index = 0;
        $length = strlen($encoded);
        $latitude = 0;
        $longitude = 0;
        $positions = [];
        while ($index < $length) {
            $latitude += self::decodeValue($encoded, $index);
            $longitude += self::decodeValue($encoded, $index);
            $lat = $latitude / 1_000_000;
            $lon = $longitude / 1_000_000;
            if (! self::validPosition($lat, $lon)) {
                throw new UnexpectedValueException('Decoded coordinate is outside valid ranges.');
            }
            $positions[] = [$lon, $lat];
        }

        if (count($positions) < 2) {
            throw new UnexpectedValueException('Encoded polyline has fewer than two positions.');
        }

        return $positions;
    }

    private static function decodeValue(string $encoded, int &$index): int
    {
        $result = 0;
        $shift = 0;
        $length = strlen($encoded);
        do {
            if ($index >= $length || $shift > 55) {
                throw new UnexpectedValueException('Encoded polyline is truncated or overflows.');
            }
            $byte = ord($encoded[$index++]) - 63;
            if ($byte < 0 || $byte > 63) {
                throw new UnexpectedValueException('Encoded polyline contains invalid characters.');
            }
            $result |= ($byte & 0x1F) << $shift;
            $shift += 5;
        } while ($byte >= 0x20);

        return ($result & 1) !== 0 ? ~($result >> 1) : ($result >> 1);
    }

    private static function validPosition(float $latitude, float $longitude): bool
    {
        return is_finite($latitude) && is_finite($longitude)
            && $latitude >= -90 && $latitude <= 90
            && $longitude >= -180 && $longitude <= 180;
    }
}
