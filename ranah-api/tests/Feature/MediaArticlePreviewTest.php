<?php

namespace Tests\Feature;

use App\Services\MediaArticlePreview;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Http;
use Tests\TestCase;

class MediaArticlePreviewTest extends TestCase
{
    public function test_publisher_metadata_is_used_when_no_recognized_article_container_exists(): void
    {
        Cache::flush();
        $url = 'https://www.antaranews.com/berita/123/erupsi';
        Http::fake([$url => Http::response('<html><head><meta property="og:description" content="Warga terdampak erupsi mendapat bantuan dan pendampingan di pengungsian."><meta property="og:image" content="https://cdn.antaranews.com/cover.jpg"></head><body><article>SELURUH ISI ARTIKEL TIDAK DISALIN</article></body></html>')]);
        $item = ['url_sumber' => $url, 'isi' => 'Judul singkat', 'gambar' => null];
        $service = app(MediaArticlePreview::class);
        $service->warm([$item]);
        $result = $service->apply($item);
        $this->assertStringContainsString('pendampingan', $result['isi']);
        $this->assertStringNotContainsString('SELURUH ISI', $result['isi']);
        $this->assertStringContainsString('/api/berita-media/', $result['gambar']);
        $service->warm([$item]);
        Http::assertSentCount(1);
    }

    public function test_listing_does_not_fetch_metadata_and_background_warming_adds_the_cover(): void
    {
        Cache::flush();
        config(['services.media_news.enabled' => true, 'services.media_news.previews' => true]);
        $url = 'https://www.antaranews.com/berita/456/marapi';
        $rss = '<rss><channel><item><title>Erupsi Gunung Marapi</title><link>'.$url.'</link><description>Erupsi Gunung Marapi berdampak pada warga.</description><pubDate>'.now()->subHour()->toRfc2822String().'</pubDate></item></channel></rss>';
        Http::fake(['www.antaranews.com/rss/*' => Http::response($rss), $url => Http::response('<meta property="og:image" content="https://cdn.antaranews.com/cover.jpg"><meta name="description" content="Pratinjau penerbit tentang penanganan pengungsi.">')]);
        $this->getJson('/api/berita')->assertOk();
        Http::assertSentCount(4);
        $this->artisan('ranah:refresh-news-previews')->assertSuccessful();
        $this->getJson('/api/berita')->assertOk()->assertJsonPath('data.0.gambar', fn ($url) => str_contains($url, '/api/berita-media/'));
    }

    public function test_google_headline_resolves_to_exact_publisher_article_and_cover(): void
    {
        Cache::flush();
        $index = 'https://news.google.com/rss/articles/TOKEN';
        $article = 'https://sumbar.antaranews.com/berita/123/marapi';
        $title = 'Bantuan warga terdampak erupsi Marapi';
        Http::fake([
            'sumbar.antaranews.com/search*' => Http::response('<a href="'.$article.'">'.$title.'</a>'),
            $article => Http::response('<meta name="description" content="Bantuan disalurkan kepada warga terdampak erupsi."><meta property="og:image" content="https://cdn.antaranews.com/cover.jpg"><article><p>'.str_repeat('keterangan ', 50).'</p></article>'),
        ]);
        $item = ['judul' => $title, 'sumber' => 'ANTARA News Sumbar', 'url_sumber' => $index, 'isi' => $title, 'gambar' => null];
        $service = app(MediaArticlePreview::class);
        $service->warm([$item]);
        $result = $service->apply($item);
        $this->assertSame($article, $result['url_sumber']);
        $this->assertStringContainsString('/api/berita-media/', $result['gambar']);
        $this->assertStringContainsString('Bantuan disalurkan', $result['isi']);
        $this->assertSame(25, substr_count($result['isi'], 'keterangan'));
        Http::assertSentCount(2);
    }

    public function test_antara_content_container_preserves_all_paragraphs_and_excludes_related_news(): void
    {
        Cache::flush();
        $url = 'https://sumbar.antaranews.com/berita/123/latihan';
        $html = '<meta property="og:image" content="https://img.antaranews.com/cache/1200x800/cover.jpg"><meta name="description" content="Deskripsi pendek."><article><div id="newsPost_content"><p>Paragraf pertama menjelaskan persiapan latihan.</p><p>Paragraf kedua menjelaskan koordinasi petugas.</p><aside><p>IKLAN TIDAK BOLEH IKUT.</p></aside><p>Baca juga: tautan lain.</p><script>TEKS SCRIPT</script><p>Paragraf terakhir menjelaskan tindak lanjut.</p></div><div><p>BERITA TERKAIT TIDAK BOLEH IKUT.</p></div><figcaption>Foto: ANTARA/HO</figcaption><span itemprop="author">Penulis contoh</span></article>';
        Http::fake([$url => Http::response($html)]);
        $service = app(MediaArticlePreview::class);
        $service->warm([['url_sumber' => $url]]);
        $result = $service->apply(['url_sumber' => $url, 'isi' => 'Judul lama']);
        $this->assertSame("Paragraf pertama menjelaskan persiapan latihan.\n\nParagraf kedua menjelaskan koordinasi petugas.\n\nParagraf terakhir menjelaskan tindak lanjut.", $result['isi']);
        $this->assertTrue($result['isi_tersedia']);
        $this->assertSame('Foto: ANTARA/HO', $result['gambar_keterangan']);
        $this->assertSame('Penulis contoh', $result['penulis']);
        $this->assertStringContainsString('/api/berita-media/', $result['gambar']);
    }

    public function test_cached_top_twelve_do_not_starve_later_articles(): void
    {
        Cache::flush();
        $items = [];
        for ($i = 0; $i < 13; $i++) {
            $url = 'https://www.antaranews.com/berita/'.($i + 1).'/contoh';
            $items[] = ['url_sumber' => $url, 'isi' => 'Pratinjau'];
            if ($i < 12) {
                Cache::put('media-preview-v3:'.hash('sha256', $url), [], 3600);
            }
        }
        Http::fake(['*' => Http::response('<div id="newsPost_content"><p>Isi artikel urutan ketiga belas.</p></div>')]);
        $service = app(MediaArticlePreview::class);
        $service->warm($items);
        $this->assertSame('Isi artikel urutan ketiga belas.', $service->apply($items[12])['isi']);
        Http::assertSentCount(1);
    }

    public function test_cached_cover_is_served_through_api_and_untrusted_hosts_are_rejected(): void
    {
        Cache::flush();
        $key = hash('sha256', 'article');
        Cache::put('media-preview-v3:'.$key, ['image' => 'https://img.antaranews.com/cover.png'], 3600);
        $png = base64_decode('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+aO1sAAAAASUVORK5CYII=');
        Http::fake(['img.antaranews.com/*' => Http::response($png, 200, ['Content-Type' => 'image/png'])]);
        $path = '/api/berita-media/'.$key.'/gambar';
        $this->withHeaders(['Origin' => 'http://localhost:5000'])->get($path)->assertOk()->assertHeader('Content-Type', 'image/png')->assertHeader('Access-Control-Allow-Origin', '*')->assertContent($png);
        $this->get($path)->assertOk();
        Http::assertSentCount(1);
        Cache::put('media-preview-v3:'.$key, ['image' => 'http://127.0.0.1/private'], 3600);
        $this->get($path)->assertNotFound();
        Http::assertSentCount(1);
    }

    public function test_untrusted_redirect_and_failed_requests_retain_existing_preview(): void
    {
        Cache::flush();
        $url = 'https://www.antaranews.com/berita/123/erupsi';
        Http::fake([$url => Http::response('', 302, ['Location' => 'http://127.0.0.1/private'])]);
        $item = ['url_sumber' => $url, 'isi' => 'Ringkasan RSS', 'gambar' => null];
        $service = app(MediaArticlePreview::class);
        $service->warm([$item]);
        $this->assertSame($item, $service->apply($item));
        Http::assertSentCount(1);
        $this->assertSame([], $service->parse('<html/>', 'https://evil.test/berita'));
    }

    public function test_description_is_bounded_and_unsafe_image_is_ignored(): void
    {
        $result = app(MediaArticlePreview::class)->parse('<meta name="description" content="'.str_repeat('kalimat ', 200).'"><meta property="og:image" content="http://127.0.0.1/x">', 'https://www.antaranews.com/berita/1');
        $this->assertCount(75, explode(' ', $result['description']));
        $this->assertNull($result['image']);
    }
}
