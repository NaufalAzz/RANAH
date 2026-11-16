<?php

namespace Tests\Feature;

use App\Services\MediaEruptionFeed;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Http;
use Tests\TestCase;

class MediaEruptionFeedTest extends TestCase
{
    private function rss(string $title = 'Erupsi Marapi: warga mendapat bantuan', string $url = 'https://www.antaranews.com/berita/123/erupsi-marapi'): string
    {
        return '<rss version="2.0"><channel><item><title>'.htmlspecialchars($title).'</title><link>'.htmlspecialchars($url).'</link><description><![CDATA[<p>Warga sekitar Gunung Marapi menerima bantuan setelah erupsi.</p>]]></description><pubDate>'.now()->subHour()->toRfc2822String().'</pubDate></item></channel></rss>';
    }

    public function test_news_endpoint_returns_actual_publisher_headlines_and_caches_deduplicated_articles(): void
    {
        Cache::flush();
        config(['services.media_news.enabled' => true]);
        Http::fake(['www.antaranews.com/rss/*' => Http::response($this->rss())]);
        $this->getJson('/api/berita')->assertOk()->assertJsonCount(1, 'data')->assertJsonPath('data.0.judul', 'Erupsi Marapi: warga mendapat bantuan')->assertJsonPath('data.0.sumber', 'ANTARA News')->assertJsonPath('data.0.jenis_konten', 'artikel');
        $this->getJson('/api/berita')->assertOk();
        Http::assertSentCount(4);
        Cache::forget('ranah:media-eruption-v3:checked');
        Http::fake(['*' => Http::response('error', 503)]);
        $this->getJson('/api/berita')->assertOk()->assertJsonCount(1, 'data');
    }

    public function test_source_failure_never_substitutes_magma_or_local_news(): void
    {
        Cache::flush();
        config(['services.media_news.enabled' => true]);
        Http::fake(['*' => Http::response('blocked', 403)]);
        $this->getJson('/api/berita')->assertStatus(503)->assertJsonPath('data', []);
        $this->getJson('/api/berita')->assertStatus(503);
    }

    public function test_valid_feed_without_eruption_news_returns_an_empty_list(): void
    {
        $parser = app(MediaEruptionFeed::class);
        $this->assertSame([], $parser->parse('<rss><channel><item><title>Wisata ke gunung</title><description>Liburan di Semeru</description><link>https://www.antaranews.com/berita/1/wisata</link><pubDate>'.now()->subHour()->toRfc2822String().'</pubDate></item></channel></rss>'));
        $this->assertSame([], $parser->parse($this->rss('Erupsi Marapi', 'https://evil.test/berita/1')));
        $this->assertCount(1, $parser->parse($this->rss()));
    }

    public function test_empty_generic_feeds_trigger_targeted_search(): void
    {
        Cache::flush();
        config(['services.media_news.enabled' => true]);
        $xml = '<rss><channel><item><title>Warga Gunung Marapi terima bantuan erupsi - ANTARA News</title><link>https://news.google.com/rss/articles/VALIDtoken</link><source url="https://www.antaranews.com">ANTARA News</source><pubDate>'.now()->subHour()->toRfc2822String().'</pubDate></item></channel></rss>';
        Http::fake(['www.antaranews.com/rss/*' => Http::response('<rss><channel/></rss>'), 'news.google.com/*' => Http::response($xml)]);
        $this->getJson('/api/berita')->assertOk()->assertJsonCount(1, 'data')->assertJsonPath('data.0.sumber', 'ANTARA News')->assertJsonPath('data.0.judul', 'Warga Gunung Marapi terima bantuan erupsi');
        Http::assertSentCount(1);
        $this->assertSame([], app(MediaEruptionFeed::class)->parse(str_replace('https://www.antaranews.com', 'https://untrusted.test', $xml), true));
    }

    public function test_diagnostic_refresh_populates_the_api_without_flushing_other_cache(): void
    {
        Cache::flush();
        config(['services.media_news.enabled' => true]);
        Cache::put('ranah:media-eruption-v3', [], 900);
        Cache::put('ranah:media-eruption-v3:checked', true, 900);
        Cache::put('unrelated', 'keep', 900);
        Http::fake(['*' => Http::response($this->rss())]);
        $this->artisan('ranah:check-news --refresh')->assertSuccessful();
        $this->getJson('/api/berita')->assertOk()->assertJsonCount(1, 'data');
        $this->assertSame('keep', Cache::get('unrelated'));
    }

    public function test_unsafe_xml_is_rejected(): void
    {
        $this->expectException(\RuntimeException::class);
        app(MediaEruptionFeed::class)->parse('<!DOCTYPE rss [<!ENTITY x SYSTEM "file:///etc/passwd">]><rss><channel/></rss>');
    }
}
