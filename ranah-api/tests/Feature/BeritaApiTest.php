<?php

namespace Tests\Feature;

use App\Models\Berita;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Carbon;
use Tests\TestCase;

class BeritaApiTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        Carbon::setTestNow('2026-10-23 12:00:00');
    }

    protected function tearDown(): void
    {
        Carbon::setTestNow();
        parent::tearDown();
    }

    public function test_index_returns_published_dated_news_in_publication_order(): void
    {
        $older = $this->createBerita([
            'judul' => 'Berita lama',
            'waktu_publikasi' => '2026-10-20 09:00:00',
        ]);
        $newer = $this->createBerita([
            'judul' => 'Berita baru',
            'waktu_publikasi' => '2026-10-22 09:00:00',
        ]);
        $this->createBerita([
            'judul' => 'Draft',
            'status_publikasi' => 'draft',
        ]);
        $this->createBerita([
            'judul' => 'Belum bertanggal',
            'waktu_publikasi' => null,
        ]);
        $this->createBerita([
            'judul' => 'Terjadwal',
            'waktu_publikasi' => '2026-10-24 09:00:00',
        ]);

        $this->getJson('/api/berita')
            ->assertOk()
            ->assertJsonPath('success', true)
            ->assertJsonStructure([
                'success',
                'message',
                'data' => [[
                    'id', 'judul', 'kategori', 'isi', 'gambar', 'sumber',
                    'waktu_publikasi',
                ]],
            ])
            ->assertJsonCount(2, 'data')
            ->assertJsonPath('data.0.id', $newer->id)
            ->assertJsonPath('data.1.id', $older->id);
    }

    public function test_index_returns_empty_list_when_no_news_is_published(): void
    {
        $this->createBerita(['status_publikasi' => 'draft']);

        $this->getJson('/api/berita')
            ->assertOk()
            ->assertJsonPath('success', true)
            ->assertJsonPath('data', []);
    }

    public function test_detail_returns_published_news_and_nullable_fields(): void
    {
        $item = $this->createBerita([
            'gambar' => null,
            'sumber' => null,
        ]);

        $this->getJson("/api/berita/{$item->id}")
            ->assertOk()
            ->assertJsonPath('success', true)
            ->assertJsonPath('data.id', $item->id)
            ->assertJsonPath('data.gambar', null)
            ->assertJsonPath('data.sumber', null);
    }

    public function test_detail_hides_missing_draft_and_future_news(): void
    {
        $draft = $this->createBerita(['status_publikasi' => 'draft']);
        $future = $this->createBerita([
            'waktu_publikasi' => '2026-10-24 09:00:00',
        ]);

        $this->getJson('/api/berita/999999')->assertNotFound();
        $this->getJson("/api/berita/{$draft->id}")->assertNotFound();
        $this->getJson("/api/berita/{$future->id}")->assertNotFound();
    }

    /** @param array<string, mixed> $overrides */
    private function createBerita(array $overrides = []): Berita
    {
        return Berita::query()->create(array_merge([
            'judul' => 'Berita uji',
            'kategori' => 'Erupsi',
            'isi' => 'Isi berita uji.',
            'gambar' => null,
            'sumber' => 'Sumber uji',
            'waktu_publikasi' => '2026-10-21 09:00:00',
            'status_publikasi' => 'published',
        ], $overrides));
    }
}
