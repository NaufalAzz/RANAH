<?php

namespace App\Services;

use JsonException;
use RuntimeException;

class OsmAssemblyPointService
{
    public function __construct(private readonly ?string $sourcePath = null)
    {
    }

    /** @return array{metadata: array<string, mixed>, features: list<array<string, mixed>>} */
    public function read(): array
    {
        $path = $this->sourcePath ?? resource_path('geojson/ranah_padang_osm.geojson');

        try {
            $contents = file_get_contents($path);
            if ($contents === false) {
                throw new RuntimeException('The OSM source file could not be read.');
            }

            $collection = json_decode($contents, true, 512, JSON_THROW_ON_ERROR);
        } catch (JsonException|RuntimeException $exception) {
            throw new RuntimeException('The OSM reference dataset is unavailable or invalid.', previous: $exception);
        }

        if (! is_array($collection)
            || ($collection['type'] ?? null) !== 'FeatureCollection'
            || ! is_array($collection['features'] ?? null)) {
            throw new RuntimeException('The OSM reference dataset is not a GeoJSON FeatureCollection.');
        }

        $features = [];
        foreach ($collection['features'] as $feature) {
            $features[] = $this->normalizeFeature($feature);
        }

        return [
            'metadata' => [
                'sumber' => 'OpenStreetMap melalui HOT Export Tool',
                'url_sumber' => 'https://www.openstreetmap.org/',
                'lisensi' => 'ODbL-1.0',
                'url_lisensi' => 'https://www.openstreetmap.org/copyright',
                'atribusi' => '© OpenStreetMap contributors',
                'tanggal_export' => null,
                'cakupan' => 'Hanya dua fitur dalam ekspor ini; bukan inventaris seluruh Kota Padang.',
                'status_verifikasi' => 'Referensi OpenStreetMap — Belum Diverifikasi',
                'jumlah_fitur' => count($features),
            ],
            'features' => $features,
        ];
    }

    /** @return array<string, mixed>|null */
    public function findById(string $id): ?array
    {
        foreach ($this->read()['features'] as $feature) {
            if (($feature['id'] ?? null) === $id) {
                return $feature;
            }
        }

        return null;
    }

    /** @return array<string, mixed> */
    private function normalizeFeature(mixed $feature): array
    {
        if (! is_array($feature)
            || ($feature['type'] ?? null) !== 'Feature'
            || ! is_array($feature['properties'] ?? null)
            || ! is_array($feature['geometry'] ?? null)) {
            throw new RuntimeException('An OSM GeoJSON feature is incomplete.');
        }

        $properties = $feature['properties'];
        $osmId = filter_var($properties['osm_id'] ?? null, FILTER_VALIDATE_INT);
        $osmType = match ($properties['osm_type'] ?? null) {
            'nodes', 'node' => 'node',
            'ways_poly', 'ways', 'way' => 'way',
            default => null,
        };

        if ($osmId === false || $osmId === null || $osmId < 1 || $osmType === null) {
            throw new RuntimeException('An OSM feature has no valid OSM identity.');
        }

        $geometry = $this->normalizeGeometry($feature['geometry']);
        $osmUrl = "https://www.openstreetmap.org/{$osmType}/{$osmId}";

        return [
            'id' => "{$osmType}/{$osmId}",
            'osm_id' => $osmId,
            'osm_type' => $osmType,
            'nama' => $this->nullableString($properties['name'] ?? null),
            'geometri' => $geometry,
            'atribut_sumber' => [
                'emergency' => $this->nullableString($properties['emergency'] ?? null),
                'assembly_point' => $this->nullableString($properties['assembly_point'] ?? null),
                'assembly_point_tsunami' => $this->nullableString($properties['assembly_point_tsunami'] ?? null),
                'ref' => $this->nullableString($properties['ref'] ?? null),
                'operator' => $this->nullableString($properties['operator'] ?? null),
                'access' => $this->nullableString($properties['access'] ?? null),
                'source' => $this->nullableString($properties['source'] ?? null),
                'tanggal_pembaruan' => $this->nullableString($properties['timestamp'] ?? null),
            ],
            'jenis_bencana' => null,
            'status_verifikasi' => 'Referensi OpenStreetMap — Belum Diverifikasi',
            'terverifikasi' => false,
            'url_osm' => $osmUrl,
        ];
    }

    /** @param array<string, mixed> $geometry
     *  @return array{type: 'Point', coordinates: array{float, float}}|array{type: 'Polygon', coordinates: list<list<array{float, float}>>}
     */
    private function normalizeGeometry(array $geometry): array
    {
        $type = $geometry['type'] ?? null;
        $coordinates = $geometry['coordinates'] ?? null;

        if ($type === 'Point') {
            return ['type' => 'Point', 'coordinates' => $this->position($coordinates)];
        }

        if ($type !== 'Polygon' || ! is_array($coordinates) || $coordinates === []) {
            throw new RuntimeException('An OSM feature has an unsupported or empty geometry.');
        }

        $rings = [];
        foreach ($coordinates as $ring) {
            if (! is_array($ring) || count($ring) < 4) {
                throw new RuntimeException('An OSM polygon ring must contain at least four positions.');
            }

            $positions = array_map(fn (mixed $position): array => $this->position($position), $ring);
            $first = $positions[0];
            $last = $positions[array_key_last($positions)];
            if ($first !== $last) {
                throw new RuntimeException('An OSM polygon ring must be closed.');
            }
            $rings[] = $positions;
        }

        return ['type' => 'Polygon', 'coordinates' => $rings];
    }

    /** @return array{float, float} GeoJSON order: longitude, latitude. */
    private function position(mixed $position): array
    {
        if (! is_array($position) || count($position) < 2
            || ! is_numeric($position[0] ?? null) || ! is_numeric($position[1] ?? null)) {
            throw new RuntimeException('An OSM geometry contains an invalid coordinate.');
        }

        $longitude = (float) $position[0];
        $latitude = (float) $position[1];
        if (! is_finite($longitude) || ! is_finite($latitude)
            || $longitude < -180 || $longitude > 180
            || $latitude < -90 || $latitude > 90) {
            throw new RuntimeException('An OSM coordinate is outside longitude/latitude bounds.');
        }

        return [$longitude, $latitude];
    }

    private function nullableString(mixed $value): ?string
    {
        if (! is_string($value) && ! is_numeric($value)) {
            return null;
        }

        $value = trim((string) $value);
        return $value === '' ? null : $value;
    }
}
