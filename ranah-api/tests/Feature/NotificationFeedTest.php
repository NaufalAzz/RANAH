<?php

namespace Tests\Feature;

use App\Models\Berita;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Cache;
use Tests\TestCase;

class NotificationFeedTest extends TestCase
{
    use RefreshDatabase;

    public function test_feed_only_returns_recent_sumbar_bmkg_events_and_active_warnings(): void
    {
        Berita::query()->create($this->item([
            'judul' => 'Gempa BMKG relevan',
            'kategori' => 'Gempa',
            'jenis_konten' => 'kejadian',
            'sumber_id' => 'bmkg-quake:sumbar-recent',
            'url_sumber' => 'https://data.bmkg.go.id/DataMKG/TEWS/gempadirasakan.json',
            'wilayah' => 'Dirasakan: Kota Padang; Episenter: Agam',
            'waktu_publikasi' => null,
            'waktu_kejadian' => now()->subHour(),
            'waktu_berakhir' => null,
        ]));
        Berita::query()->create($this->item([
            'judul' => 'Peringatan BMKG aktif',
            'kategori' => 'Cuaca',
            'jenis_konten' => 'peringatan',
            'sumber_id' => 'bmkg-cap:active',
            'url_sumber' => 'https://www.bmkg.go.id/alerts/nowcast/id/active_alert.xml',
            'wilayah' => 'Kabupaten Agam',
            'waktu_publikasi' => now()->subMinutes(20),
            'waktu_kejadian' => now()->subMinutes(10),
            'waktu_berakhir' => now()->addMinutes(30),
        ]));
        Berita::query()->create($this->item([
            'judul' => 'Peringatan BMKG kedaluwarsa',
            'jenis_konten' => 'peringatan',
            'sumber_id' => 'bmkg-cap:expired',
            'wilayah' => 'Kota Padang',
            'waktu_publikasi' => now()->subHours(2),
            'waktu_kejadian' => now()->subHour(),
            'waktu_berakhir' => now()->subMinute(),
        ]));
        Berita::query()->create($this->item([
            'judul' => 'Gempa BMKG lama',
            'jenis_konten' => 'kejadian',
            'sumber_id' => 'bmkg-quake:old',
            'wilayah' => 'Kota Padang',
            'waktu_publikasi' => null,
            'waktu_kejadian' => now()->subDays(8),
            'waktu_berakhir' => null,
        ]));
        Berita::query()->create($this->item([
            'judul' => 'Gempa di luar Sumbar',
            'jenis_konten' => 'kejadian',
            'sumber_id' => 'bmkg-quake:outside',
            'wilayah' => 'Dirasakan: Kota Sorong; Episenter: Kota Sorong',
            'waktu_publikasi' => null,
            'waktu_kejadian' => now()->subMinutes(5),
            'waktu_berakhir' => null,
        ]));
        Berita::query()->create($this->item([
            'judul' => 'Berita lama sumber lain',
            'sumber' => 'BNPB',
            'sumber_id' => 'bnpb:archive',
            'jenis_konten' => 'kejadian',
            'wilayah' => 'Kota Padang',
        ]));
        Cache::put('bmkg_earthquake_last_success_at', '2026-10-25T01:15:00+00:00');

        $this->getJson('/api/notifikasi?per_page=10')
            ->assertOk()
            ->assertJsonCount(2, 'data')
            ->assertJsonPath('data.0.judul', 'Peringatan BMKG aktif')
            ->assertJsonPath('data.0.status', 'aktif')
            ->assertJsonPath('data.0.cakupan_wilayah', 'Sumatera Barat')
            ->assertJsonPath('data.0.rentang_gempa_hari', 7)
            ->assertJsonPath('data.1.judul', 'Gempa BMKG relevan')
            ->assertJsonPath('data.1.status', 'informasi')
            ->assertJsonPath('meta.total', 2)
            ->assertJsonPath('meta.waktu_pembaruan_terakhir_bmkg', '2026-10-25T01:15:00+00:00');
    }

    public function test_feed_excludes_drafts_and_future_source_times(): void
    {
        Berita::query()->create($this->item([
            'sumber_id' => 'bmkg-quake:draft',
            'jenis_konten' => 'kejadian',
            'status_publikasi' => 'draft',
            'waktu_publikasi' => null,
            'waktu_kejadian' => now()->subHour(),
            'waktu_berakhir' => null,
        ]));
        Berita::query()->create($this->item([
            'sumber_id' => 'bmkg-quake:future',
            'jenis_konten' => 'kejadian',
            'waktu_publikasi' => null,
            'waktu_kejadian' => now()->addHour(),
            'waktu_berakhir' => null,
        ]));
        Berita::query()->create($this->item([
            'sumber_id' => 'bmkg-cap:future',
            'jenis_konten' => 'peringatan',
            'waktu_publikasi' => now()->addMinute(),
            'waktu_kejadian' => now()->addHour(),
            'waktu_berakhir' => now()->addHours(2),
        ]));

        $this->getJson('/api/notifikasi')
            ->assertOk()
            ->assertJsonPath('data', [])
            ->assertJsonPath('meta.total', 0);
    }

    public function test_public_client_can_read_notification_feed_cross_origin(): void
    {
        $this->withHeaders([
            'Origin' => 'https://ranah-mobile.example',
            'Access-Control-Request-Method' => 'GET',
        ])->options('/api/notifikasi')
            ->assertNoContent()
            ->assertHeader('Access-Control-Allow-Origin', '*');
    }

    /** @param array<string, mixed> $overrides
     * @return array<string, mixed>
     */
    private function item(array $overrides = []): array
    {
        return array_merge([
            'judul' => 'Fixture notifikasi BMKG',
            'kategori' => 'Gempa',
            'jenis_konten' => 'kejadian',
            'isi' => 'Data fixture untuk menguji kontrak endpoint.',
            'gambar' => null,
            'sumber' => 'BMKG',
            'sumber_id' => 'bmkg-quake:fixture',
            'tingkat_kepentingan' => null,
            'url_sumber' => 'https://data.bmkg.go.id/gempabumi/',
            'wilayah' => 'Kota Padang',
            'waktu_publikasi' => null,
            'waktu_kejadian' => now()->subMinutes(10),
            'waktu_berakhir' => null,
            'waktu_pengambilan' => now(),
            'status_publikasi' => 'published',
        ], $overrides);
    }
}
