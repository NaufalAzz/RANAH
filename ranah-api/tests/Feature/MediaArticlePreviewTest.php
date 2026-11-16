<?php

namespace Tests\Feature;

use App\Services\MediaArticlePreview;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Http;
use Tests\TestCase;

class MediaArticlePreviewTest extends TestCase
{
    public function test_publisher_description_and_cover_are_cached_and_applied_without_copying_full_article(): void
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
        $this->assertSame('https://cdn.antaranews.com/cover.jpg', $result['gambar']);
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
        $this->getJson('/api/berita')->assertOk()->assertJsonPath('data.0.gambar', 'https://cdn.antaranews.com/cover.jpg');
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
