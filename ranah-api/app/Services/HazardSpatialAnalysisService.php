<?php

namespace App\Services;

use Illuminate\Http\Client\ConnectionException;
use Illuminate\Http\Client\RequestException;
use Illuminate\Support\Facades\Http;
use UnexpectedValueException;

class HazardSpatialAnalysisService
{
    private const string QUERY_URL = 'https://kspservices.big.go.id/satupeta/rest/services/PUBLIK/SUMBER_DAYA_ALAM_DAN_LINGKUNGAN/MapServer/11/query';

    private const string SOURCE_NAME = 'Badan Informasi Geospasial (BIG), Satu Peta';

    private const string SOURCE_URL = 'https://kspservices.big.go.id/satupeta/rest/services/PUBLIK/SUMBER_DAYA_ALAM_DAN_LINGKUNGAN/MapServer/11';

    public function __construct(private readonly InaRiskRasterAnalysisService $inaRisk) {}

    /**
     * Check a WGS84 point against the source feature geometry. Coordinates are
     * sent at their original precision; no location history or cache is kept.
     *
     * @return array<string, mixed>
     */
    public function analyze(float $latitude, float $longitude): array
    {
        $analyzedAt = now()->toIso8601String();

        return [
            'waktu_analisis' => $analyzedAt,
            'sistem_koordinat' => 'EPSG:4326',
            'bahaya' => [
                'tsunami' => $this->inaRisk->analyze('tsunami', $latitude, $longitude),
                'banjir' => $this->inaRisk->analyze('banjir', $latitude, $longitude),
                'gempa_bumi' => $this->inaRisk->analyze('gempa_bumi', $latitude, $longitude),
                'letusan_gunung_api' => $this->analyzeVolcanoKrb($latitude, $longitude),
            ],
        ];
    }

    /** @return array<string, mixed> */
    private function analyzeVolcanoKrb(float $latitude, float $longitude): array
    {
        if (! $this->insideServiceExtent($latitude, $longitude)) {
            return $this->volcanoStatus(
                'di_luar_cakupan_layer',
                'Titik berada di luar extent layanan KRB BIG yang diperiksa. Ini bukan penilaian bahwa lokasi aman dari bahaya lain.',
            );
        }

        try {
            $response = Http::connectTimeout(5)
                ->timeout(12)
                ->acceptJson()
                ->get(self::QUERY_URL, [
                    'f' => 'json',
                    'geometry' => json_encode([
                        'x' => $longitude,
                        'y' => $latitude,
                        'spatialReference' => ['wkid' => 4326],
                    ], JSON_THROW_ON_ERROR),
                    'geometryType' => 'esriGeometryPoint',
                    'inSR' => 4326,
                    'spatialRel' => 'esriSpatialRelIntersects',
                    'outFields' => 'objectid,namobj,indga,thterbit,metadata',
                    'returnGeometry' => 'false',
                ]);

            $response->throw();
            $payload = $response->json();
            if (! is_array($payload) || isset($payload['error']) || ! is_array($payload['features'] ?? null)) {
                throw new UnexpectedValueException('BIG returned an unrecognized feature response.');
            }
            if (($payload['exceededTransferLimit'] ?? false) === true) {
                throw new UnexpectedValueException('BIG feature response exceeded its transfer limit.');
            }

            $matches = array_map(
                fn (mixed $feature): array => $this->parseFeature($feature),
                $payload['features'],
            );
        } catch (ConnectionException|RequestException $exception) {
            return $this->volcanoStatus(
                'layanan_gagal',
                'Layanan geospasial BIG tidak dapat memberikan hasil yang dapat divalidasi saat ini.',
            );
        } catch (UnexpectedValueException) {
            return $this->volcanoStatus(
                'analisis_tidak_dapat_ditentukan',
                'Respons geospasial BIG tidak dapat divalidasi.',
            );
        } catch (\JsonException) {
            return $this->volcanoStatus(
                'analisis_tidak_dapat_ditentukan',
                'Koordinat tidak dapat disiapkan untuk pemeriksaan spasial.',
            );
        } catch (\Throwable) {
            return $this->volcanoStatus(
                'analisis_tidak_dapat_ditentukan',
                'Respons geospasial BIG tidak dapat divalidasi.',
            );
        }

        if ($matches === []) {
            return $this->volcanoStatus(
                'no_data',
                'Tidak ditemukan fitur KRB yang beririsan pada layer BIG ini. Data yang tidak ditemukan bukan bukti bahwa lokasi aman.',
            );
        }

        return [
            'status' => 'hasil_tersedia',
            'penjelasan' => 'Titik beririsan dengan fitur Kawasan Rawan Bencana gunung api pada layer BIG yang diperiksa.',
            'metode' => 'Query spasial point-intersects pada geometri sumber BIG; koordinat EPSG:4326 dikirim tanpa pembulatan.',
            'sumber' => self::SOURCE_NAME,
            'url_sumber' => self::SOURCE_URL,
            'fitur' => $matches,
            'keterbatasan' => $this->limitations(),
        ];
    }

    /** @return array<string, mixed> */
    private function parseFeature(mixed $feature): array
    {
        $attributes = is_array($feature) ? ($feature['attributes'] ?? null) : null;
        if (! is_array($attributes)) {
            throw new UnexpectedValueException('BIG feature attributes are missing.');
        }

        $sourceId = filter_var($attributes['objectid'] ?? null, FILTER_VALIDATE_INT);
        $name = trim((string) ($attributes['namobj'] ?? ''));
        $zone = filter_var($attributes['indga'] ?? null, FILTER_VALIDATE_INT);
        $yearValue = $attributes['thterbit'] ?? null;
        $year = $yearValue === null || $yearValue === ''
            ? null
            : filter_var($yearValue, FILTER_VALIDATE_INT);
        $metadata = trim((string) ($attributes['metadata'] ?? ''));

        if ($sourceId === false || $name === '' || ! in_array($zone, [1, 2, 3], true)
            || ($yearValue !== null && $yearValue !== '' && $year === false)
            || ($metadata !== '' && $metadata !== 'IGT58_KAWASANRAWANBENCANAGUNUNGAPI_AR')) {
            throw new UnexpectedValueException('BIG feature attributes failed validation.');
        }

        return [
            'nama_gunung' => $name,
            'zona_krb' => 'KRB '.['I', 'II', 'III'][$zone - 1],
            'indga' => $zone,
            'tahun_peta' => $year,
            'id_fitur_sumber' => $sourceId,
        ];
    }

    private function insideServiceExtent(float $latitude, float $longitude): bool
    {
        return $longitude >= 95.287544646 && $longitude <= 129.916699233
            && $latitude >= -8.959987406 && $latitude <= 5.839659686;
    }

    /** @return array<string, mixed> */
    private function volcanoStatus(string $status, string $explanation): array
    {
        return [
            'status' => $status,
            'penjelasan' => $explanation,
            'metode' => 'Query spasial point-intersects terhadap layer poligon BIG.',
            'sumber' => self::SOURCE_NAME,
            'url_sumber' => self::SOURCE_URL,
            'fitur' => [],
            'keterbatasan' => $this->limitations(),
        ];
    }

    private function limitations(): string
    {
        return 'Tahun peta berbeda antarfitur dan dapat lama. Hasil hanya menyatakan kecocokan pada layer ini, bukan status aktivitas MAGMA, prediksi erupsi, atau panduan evakuasi. Tidak ditemukannya fitur bukan berarti aman; ikuti informasi dan arahan terbaru PVMBG/BPBD.';
    }
}
