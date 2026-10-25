<?php

namespace Tests\Feature;

use App\Models\Gunung;
use App\Models\LaporanGunung;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class GunungApiTest extends TestCase
{
    use RefreshDatabase;

    public function test_index_returns_only_active_gunung_and_flutter_list_fields(): void
    {
        $active = $this->createGunung([
            'nama' => 'Gunung Aktif',
            'status_aktivitas' => null,
            'kabupaten' => null,
            'latitude' => null,
            'longitude' => null,
            'radius_perkiraan_km' => null,
            'sumber_data' => null,
            'sumber_koordinat' => 'BIG e-Atlas',
            'sumber_koordinat_id' => '14',
            'sumber_validasi_administratif' => 'geoBoundaries IDN ADM1 (2017)',
            'sumber_validasi_administratif_id' => 'sample-adm1-shape-id',
            'status_validasi_koordinat' => 'terverifikasi',
            'waktu_validasi_koordinat' => '2026-10-25 00:00:00',
        ]);
        $this->createGunung(['nama' => 'Gunung Nonaktif', 'aktif' => false]);

        $response = $this->getJson('/api/gunung');

        $response
            ->assertOk()
            ->assertJsonPath('success', true)
            ->assertJsonStructure([
                'success',
                'message',
                'data' => [[
                    'id',
                    'nama',
                    'provinsi',
                    'kabupaten',
                    'latitude',
                    'longitude',
                    'status_aktivitas',
                    'radius_perkiraan_km',
                    'sumber_data',
                    'sumber_id',
                    'waktu_pengambilan',
                    'sumber_koordinat',
                    'sumber_koordinat_id',
                    'sumber_validasi_administratif',
                    'sumber_validasi_administratif_id',
                    'status_validasi_koordinat',
                    'waktu_validasi_koordinat',
                    'aktif',
                ]],
            ])
            ->assertJsonCount(1, 'data')
            ->assertJsonPath('data.0.id', $active->id)
            ->assertJsonPath('data.0.nama', 'Gunung Aktif')
            ->assertJsonPath('data.0.status_aktivitas', null)
            ->assertJsonPath('data.0.sumber_koordinat', 'BIG e-Atlas')
            ->assertJsonPath('data.0.sumber_koordinat_id', '14')
            ->assertJsonPath('data.0.sumber_validasi_administratif', 'geoBoundaries IDN ADM1 (2017)')
            ->assertJsonPath('data.0.sumber_validasi_administratif_id', 'sample-adm1-shape-id')
            ->assertJsonPath('data.0.status_validasi_koordinat', 'terverifikasi');
    }

    public function test_detail_returns_gunung_and_related_reports_in_defined_order(): void
    {
        $gunung = $this->createGunung();

        $this->createLaporan($gunung, [
            'sumber' => 'Laporan lama',
            'waktu_publikasi' => '2026-10-20 09:00:00',
        ]);
        $this->createLaporan($gunung, [
            'sumber' => 'Laporan seri pertama',
            'waktu_publikasi' => '2026-10-21 09:00:00',
        ]);
        $this->createLaporan($gunung, [
            'sumber' => 'Laporan seri kedua',
            'waktu_publikasi' => '2026-10-21 09:00:00',
        ]);
        $this->createLaporan($gunung, [
            'sumber' => 'Laporan terbaru',
            'waktu_publikasi' => '2026-10-22 09:00:00',
        ]);

        $response = $this->getJson("/api/gunung/{$gunung->id}");

        $response
            ->assertOk()
            ->assertJsonPath('success', true)
            ->assertJsonStructure([
                'success',
                'message',
                'data' => [
                    'gunung' => [
                        'id',
                        'nama',
                        'provinsi',
                        'kabupaten',
                        'latitude',
                        'longitude',
                        'status_aktivitas',
                        'radius_perkiraan_km',
                        'sumber_data',
                        'sumber_koordinat',
                        'sumber_koordinat_id',
                        'sumber_validasi_administratif',
                        'sumber_validasi_administratif_id',
                        'status_validasi_koordinat',
                        'waktu_validasi_koordinat',
                        'aktif',
                    ],
                    'laporan' => [[
                        'id',
                        'gunung_id',
                        'periode_mulai',
                        'periode_selesai',
                        'data_klimatologi',
                        'pengamatan_visual',
                        'rekomendasi',
                        'foto',
                        'sumber',
                        'waktu_publikasi',
                        'sumber_id',
                        'url_sumber',
                        'periode_waktu',
                        'waktu_pengambilan',
                    ]],
                ],
            ])
            ->assertJsonPath('data.gunung.id', $gunung->id)
            ->assertJsonPath('data.gunung.nama', 'Gunung Contoh')
            ->assertJsonPath('data.laporan.0.sumber', 'Laporan terbaru')
            ->assertJsonPath('data.laporan.1.sumber', 'Laporan seri kedua')
            ->assertJsonPath('data.laporan.2.sumber', 'Laporan seri pertama')
            ->assertJsonPath('data.laporan.3.sumber', 'Laporan lama');
    }

    public function test_detail_without_reports_and_with_nullable_gunung_fields_is_valid(): void
    {
        $gunung = $this->createGunung([
            'kabupaten' => null,
            'latitude' => null,
            'longitude' => null,
            'status_aktivitas' => null,
            'radius_perkiraan_km' => null,
            'sumber_data' => null,
        ]);

        $this->getJson("/api/gunung/{$gunung->id}")
            ->assertOk()
            ->assertJsonPath('success', true)
            ->assertJsonPath('data.gunung.status_aktivitas', null)
            ->assertJsonPath('data.gunung.latitude', null)
            ->assertJsonPath('data.laporan', []);
    }

    public function test_detail_serializes_nullable_report_fields_without_error(): void
    {
        $gunung = $this->createGunung();
        $laporan = $this->createLaporan($gunung, [
            'periode_mulai' => null,
            'periode_selesai' => null,
            'data_klimatologi' => null,
            'pengamatan_visual' => null,
            'rekomendasi' => null,
            'foto' => null,
            'waktu_publikasi' => null,
        ]);

        $this->getJson("/api/gunung/{$gunung->id}")
            ->assertOk()
            ->assertJsonPath('data.laporan.0.id', $laporan->id)
            ->assertJsonPath('data.laporan.0.periode_mulai', null)
            ->assertJsonPath('data.laporan.0.data_klimatologi', null)
            ->assertJsonPath('data.laporan.0.foto', null)
            ->assertJsonPath('data.laporan.0.waktu_publikasi', null);
    }

    public function test_detail_returns_not_found_for_missing_or_inactive_gunung(): void
    {
        $inactive = $this->createGunung(['aktif' => false]);

        $this->getJson('/api/gunung/999999')
            ->assertNotFound()
            ->assertJsonPath('success', false)
            ->assertJsonPath('data', null);

        $this->getJson("/api/gunung/{$inactive->id}")
            ->assertNotFound()
            ->assertJsonPath('success', false)
            ->assertJsonPath('data', null);
    }

    /** @param array<string, mixed> $overrides */
    private function createGunung(array $overrides = []): Gunung
    {
        return Gunung::query()->create(array_merge([
            'nama' => 'Gunung Contoh',
            'provinsi' => 'Sumatera Barat',
            'kabupaten' => 'Kabupaten Contoh',
            'latitude' => -0.1234567,
            'longitude' => 100.1234567,
            'status_aktivitas' => null,
            'radius_perkiraan_km' => null,
            'sumber_data' => null,
            'aktif' => true,
        ], $overrides));
    }

    /** @param array<string, mixed> $overrides */
    private function createLaporan(Gunung $gunung, array $overrides = []): LaporanGunung
    {
        return LaporanGunung::query()->create(array_merge([
            'gunung_id' => $gunung->id,
            'periode_mulai' => null,
            'periode_selesai' => null,
            'data_klimatologi' => null,
            'pengamatan_visual' => null,
            'rekomendasi' => null,
            'foto' => null,
            'sumber' => 'Sumber uji',
            'waktu_publikasi' => null,
        ], $overrides));
    }
}
