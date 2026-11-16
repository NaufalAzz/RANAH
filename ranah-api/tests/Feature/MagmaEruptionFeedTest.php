<?php

namespace Tests\Feature;

use App\Services\MagmaEruptionFeed;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Http;
use Tests\TestCase;

class MagmaEruptionFeedTest extends TestCase
{
    public function test_live_feed_is_cached_and_retained_when_source_fails(): void
    {
        Cache::flush();
        config(['services.magma_news.enabled' => true]);
        $this->travelTo(now()->setDate(2026, 11, 17));
        $html = '<div class="timeline-item"><p class="timeline-title">Marapi</p><p class="timeline-text">Terjadi erupsi G. Marapi pada hari Senin, 16 November 2026, pukul 10:00 WIB.</p><a href="https://magma.esdm.go.id/v1/gunung-api/informasi-letusan/abc-123/show">Details</a></div>';
        Http::fake([MagmaEruptionFeed::URL => Http::response($html)]);
        $this->getJson('/api/berita')->assertOk()->assertJsonPath('data.0.gunung', 'Marapi');
        $this->getJson('/api/berita')->assertOk();
        Http::assertSentCount(1);
        Cache::forget('magma:eruption-checked');
        Http::fake([MagmaEruptionFeed::URL => Http::response('error', 503)]);
        $this->getJson('/api/berita')->assertOk()->assertJsonPath('data.0.gunung', 'Marapi');
    }

    public function test_unavailable_source_does_not_invent_news(): void
    {
        Cache::flush();
        config(['services.magma_news.enabled' => true]);
        Http::fake([MagmaEruptionFeed::URL => Http::response('<html>changed</html>')]);
        $this->getJson('/api/berita')->assertStatus(503)->assertJsonPath('data', []);
    }
}
