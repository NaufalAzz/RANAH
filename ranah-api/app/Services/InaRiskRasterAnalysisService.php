<?php

namespace App\Services;

use Illuminate\Support\Facades\Http;
use Throwable;

/**
 * Reads a single pixel from BNPB InaRISK ImageServer layers. The pixel value
 * is exposed without assigning a low/medium/high class because the published
 * service metadata does not document a matching class break or data year.
 */
class InaRiskRasterAnalysisService
{
    private const float EARTH_RADIUS = 6378137.0;

    private const float WGS84_ECCENTRICITY = 0.08181919084262149;

    /** @var array<string, array{dataset: string, url: string, extent: array{0: float, 1: float, 2: float, 3: float}, year?: int|null, data_type?: string, value_type?: string, methodology_url?: string, query_method?: string, limitations?: string, connect_timeout?: int, timeout?: int}> */
    private const array LAYERS = [
        'tsunami' => [
            'dataset' => 'layer_bahaya_tsunami',
            'url' => 'https://gis.bnpb.go.id/server/rest/services/inarisk/layer_bahaya_tsunami/ImageServer',
            'extent' => [6831136.164320603, -1224895.1089675426, 15698336.164320603, 2959304.8910324574],
        ],
        'banjir' => [
            'dataset' => 'layer_bahaya_banjir',
            'url' => 'https://gis.bnpb.go.id/server/rest/services/inarisk/layer_bahaya_banjir/ImageServer',
            'extent' => [10584136.164320603, -1224895.1089675426, 15698236.164320603, 649304.8910324574],
        ],
        'gempa_bumi' => [
            'dataset' => 'INDEKS_BAHAYA_GEMPABUMI',
            'url' => 'https://gis.bnpb.go.id/server/rest/services/inarisk/INDEKS_BAHAYA_GEMPABUMI/ImageServer',
            'extent' => [10572136.164320603, -1224895.1089675426, 15698236.164320603, 673304.8910324574],
            'year' => null,
            'data_type' => 'Float32',
            'value_type' => 'Indeks bahaya gempa ternormalisasi (0–1), bukan persentase.',
            'methodology_url' => 'https://inarisk.bnpb.go.id/metodologi',
            'query_method' => 'ArcGIS ImageServer Identify; input titik X=longitude dan Y=latitude pada EPSG:4326. Dataset menggunakan grid EPSG:3395, ukuran piksel 100 m, dan resampling default bilinear.',
            'limitations' => 'Metodologi InaRISK menyusun indeks dari kelas intensitas guncangan permukaan, tetapi metadata service tidak mencantumkan tahun publikasi atau ambang kelas rendah/sedang/tinggi untuk sampel raster ini. Nilai Identify dapat terinterpolasi oleh resampling bilinear. Ini kajian bahaya wilayah, bukan kejadian gempa, prediksi, atau peringatan. NoData bukan berarti aman.',
            'connect_timeout' => 3,
            'timeout' => 4,
        ],
    ];

    /** @return array<string, mixed> */
    public function analyze(string $hazard, float $latitude, float $longitude): array
    {
        $layer = self::LAYERS[$hazard] ?? null;
        if ($layer === null) {
            return $this->status('belum_dianalisis', 'Jenis bahaya belum dianalisis.');
        }

        $base = $this->metadata($layer);
        if (! $this->insideExtent($latitude, $longitude, $layer['extent'])) {
            return $base + [
                'status' => 'titik_di_luar_cakupan',
                'penjelasan' => 'Koordinat berada di luar extent layanan raster. Ini bukan penilaian bahwa lokasi aman.',
            ];
        }

        try {
            $response = Http::connectTimeout($layer['connect_timeout'] ?? 4)
                ->timeout($layer['timeout'] ?? 8)
                ->acceptJson()
                ->get($layer['url'].'/identify', [
                    'f' => 'json',
                    'geometry' => json_encode([
                        'x' => $longitude,
                        'y' => $latitude,
                        'spatialReference' => ['wkid' => 4326],
                    ], JSON_THROW_ON_ERROR),
                    'geometryType' => 'esriGeometryPoint',
                    'sr' => 4326,
                    'returnGeometry' => 'false',
                    'returnCatalogItems' => 'false',
                ]);
            $response->throw();
            $payload = $response->json();
            if (! is_array($payload) || isset($payload['error'])) {
                return $base + [
                    'status' => 'layanan_bermasalah',
                    'penjelasan' => 'Layanan BNPB mengembalikan respons yang tidak dapat dibaca.',
                ];
            }
        } catch (Throwable) {
            return $base + [
                'status' => 'layanan_bermasalah',
                'penjelasan' => 'Informasi sementara tidak dapat dimuat dari layanan BNPB.',
            ];
        }

        if (! array_key_exists('value', $payload)) {
            return $base + [
                'status' => 'belum_dapat_ditentukan',
                'penjelasan' => 'Respons Identify tidak memuat nilai piksel yang dapat divalidasi.',
            ];
        }

        $value = $payload['value'];
        if ($value === null || (is_string($value) && strcasecmp(trim($value), 'NoData') === 0)) {
            return $base + [
                'status' => 'no_data',
                'penjelasan' => 'Data bahaya untuk koordinat ini belum tersedia atau tidak dapat dibaca.',
            ];
        }

        $numericValue = filter_var($value, FILTER_VALIDATE_FLOAT);
        if ($numericValue === false || ! is_finite((float) $numericValue)
            || $numericValue < 0 || $numericValue > 1) {
            return $base + [
                'status' => 'belum_dapat_ditentukan',
                'penjelasan' => 'Nilai raster berada di luar rentang metadata yang tersedia dan tidak ditafsirkan.',
            ];
        }

        return $base + [
            'status' => 'klasifikasi_belum_diverifikasi',
            'penjelasan' => 'Nilai piksel tersedia. Klasifikasi bahaya belum dapat diverifikasi untuk versi raster ini.',
            'nilai_piksel' => (float) $numericValue,
        ];
    }

    /** @param array{0: float, 1: float, 2: float, 3: float} $extent */
    private function insideExtent(float $latitude, float $longitude, array $extent): bool
    {
        if ($latitude <= -89.9 || $latitude >= 89.9) {
            return false;
        }

        $x = self::EARTH_RADIUS * deg2rad($longitude);
        $phi = deg2rad($latitude);
        $sinPhi = sin($phi);
        $y = self::EARTH_RADIUS * log(
            tan(M_PI_4 + ($phi / 2))
            * (((1 - self::WGS84_ECCENTRICITY * $sinPhi)
                / (1 + self::WGS84_ECCENTRICITY * $sinPhi))
                ** (self::WGS84_ECCENTRICITY / 2)),
        );

        return is_finite($x) && is_finite($y)
            && $x >= $extent[0] && $x <= $extent[2]
            && $y >= $extent[1] && $y <= $extent[3];
    }

    /** @param array{dataset: string, url: string, extent: array{0: float, 1: float, 2: float, 3: float}} $layer
     *  @return array<string, mixed>
     */
    private function metadata(array $layer): array
    {
        return [
            'jenis_bahaya' => 'bahaya_'.$this->hazardKey($layer['dataset']),
            'dataset' => $layer['dataset'],
            'sumber' => 'BNPB InaRISK GIS Services',
            'url_sumber' => $layer['url'],
            'url_metodologi' => $layer['methodology_url'] ?? null,
            'tahun_data' => $layer['year'] ?? null,
            'resolusi_piksel_meter' => 100,
            'sistem_koordinat_dataset' => 'EPSG:3395',
            'tipe_nilai' => $layer['data_type'] ?? 'Float32',
            'jenis_nilai' => $layer['value_type'] ?? 'Nilai raster mentah; makna kelas belum diverifikasi.',
            'metode_query' => $layer['query_method'] ?? 'ArcGIS ImageServer Identify pada titik dengan koordinat X=longitude dan Y=latitude, input EPSG:4326.',
            'nilai_minimum_metadata' => 0,
            'nilai_maksimum_metadata' => 1,
            'klasifikasi' => null,
            'keterbatasan' => $layer['limitations'] ?? 'Tahun raster dan definisi kelas yang cocok belum tersedia pada metadata layanan. Nilai yang ditampilkan adalah nilai piksel mentah, bukan kelas bahaya atau peringatan kejadian. NoData bukan berarti aman.',
        ];
    }

    private function hazardKey(string $dataset): string
    {
        if (str_contains(strtolower($dataset), 'tsunami')) {
            return 'tsunami';
        }
        if (str_contains(strtolower($dataset), 'gempa')) {
            return 'gempa_bumi';
        }

        return 'banjir';
    }

    /** @return array<string, mixed> */
    private function status(string $status, string $explanation): array
    {
        return [
            'status' => $status,
            'penjelasan' => $explanation,
            'klasifikasi' => null,
        ];
    }
}
