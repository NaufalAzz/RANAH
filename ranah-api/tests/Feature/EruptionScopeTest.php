<?php

namespace Tests\Feature;

use App\Models\Berita;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Http;
use Tests\TestCase;

class EruptionScopeTest extends TestCase
{
    use RefreshDatabase;

    public function test_news_and_updates_exclude_other_disasters_and_unpublished_content(): void
    {
        foreach (['Erupsi gunung api', 'Gempa', 'Banjir', 'Tsunami'] as $category) {
            Berita::query()->create([
                'judul' => $category,
                'kategori' => $category,
                'isi' => 'Informasi pengujian.',
                'sumber' => 'Sumber uji',
                'jenis_konten' => 'artikel',
                'status_publikasi' => 'published',
                'waktu_publikasi' => now()->subHour(),
            ]);
        }
        Berita::query()->create([
            'judul' => 'Belum diterbitkan',
            'kategori' => 'Erupsi',
            'isi' => 'Draft',
            'jenis_konten' => 'artikel',
            'status_publikasi' => 'draft',
            'waktu_publikasi' => now()->subHour(),
        ]);

        $this->getJson('/api/berita')->assertOk()
            ->assertJsonCount(1, 'data')
            ->assertJsonPath('data.0.kategori', 'Erupsi gunung api');
        $this->getJson('/api/notifikasi')->assertOk()
            ->assertJsonCount(1, 'data')
            ->assertJsonPath('data.0.kategori', 'Erupsi gunung api');
    }

    public function test_unverified_generic_destinations_and_routes_are_retired(): void
    {
        Http::fake();
        $this->getJson('/api/peta/titik-kumpul-osm')->assertStatus(410)
            ->assertJsonPath('code', 'eruption_evacuation_data_unavailable');
        $this->postJson('/api/peta/rute-simulasi', [
            'latitude' => -0.38, 'longitude' => 100.47, 'destination_id' => 'node/1',
        ])->assertStatus(410);
        Http::assertNothingSent();
    }

    public function test_complaint_does_not_accept_tsunami_category(): void
    {
        $this->postJson('/api/pengaduan', [
            'nama_pelapor' => 'Pelapor uji', 'nomor_telepon' => '08123456789',
            'kategori' => 'Tsunami', 'lokasi_kejadian' => 'Lokasi uji',
            'deskripsi' => 'Isi pengujian', 'persetujuan' => true,
        ])->assertUnprocessable()->assertJsonValidationErrors('kategori');
        $this->assertDatabaseCount('pengaduan', 0);
    }
}
