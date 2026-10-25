<?php

namespace Tests\Feature;

use App\Models\Berita;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Artisan;
use Tests\TestCase;

class BnpbArchiveImportTest extends TestCase
{
    use RefreshDatabase;

    public function test_curated_bnpb_csv_imports_once_and_publishes_records_to_the_normal_api(): void
    {
        Berita::query()->create([
            'judul' => '[DEMO] Informasi Mitigasi Bencana',
            'kategori' => 'Mitigasi',
            'isi' => 'Existing demo row.',
            'status_publikasi' => 'published',
        ]);

        $this->assertSame(0, Artisan::call('ranah:import-bnpb-archive'));
        $this->assertDatabaseCount('berita', 11);
        $this->assertSame(0, Artisan::call('ranah:import-bnpb-archive'));
        $this->assertDatabaseCount('berita', 11);

        $this->assertSame(10, Berita::query()
            ->where('status_publikasi', 'published')
            ->where('jenis_konten', 'kejadian')
            ->where('sumber', 'like', 'BNPB%')
            ->count());
        $this->assertSame(0, Berita::query()
            ->where('status_publikasi', 'draft')
            ->where('sumber', 'like', 'BNPB%')
            ->count());

        $this->getJson('/api/berita')
            ->assertOk()
            ->assertJsonCount(10, 'data')
            ->assertJsonFragment(['judul' => 'Tanah Longsor di Agam, Provinsi Sumatera Barat']);

        $item = Berita::query()
            ->where('judul', 'Tanah Longsor di Agam, Provinsi Sumatera Barat')
            ->firstOrFail();

        $this->assertSame('published', $item->status_publikasi);
        $this->assertNotNull($item->waktu_publikasi);
        $this->assertNull($item->waktu_kejadian);
        $this->assertNull($item->sumber_id);
        $this->assertNull($item->url_sumber);
        $this->assertNotNull($item->waktu_pengambilan);
        $this->assertStringContainsString('2026-05-05', $item->isi);
        $this->assertStringContainsString('buletin-info-bencana-mei-2026.pdf', $item->isi);
        $this->assertStringContainsString('BNPB-2026-05-AGAM-LANDSLIDE-001', $item->isi);
        $this->assertStringContainsString('Tanggal publikasi sumber tidak tercantum', $item->isi);
        $this->assertStringNotContainsString('Arsip akademik', $item->isi);
    }
}
