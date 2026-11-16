<?php

namespace App\Services;

use Carbon\CarbonImmutable;
use DOMDocument;
use DOMXPath;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Http;
use RuntimeException;

/** Publisher-provided RSS summaries only; never scrape full copyrighted articles. */
class MediaEruptionFeed
{
    public const FEEDS = [
        'https://www.antaranews.com/rss/humaniora.xml',
        'https://www.antaranews.com/rss/warta-bumi.xml',
        'https://www.antaranews.com/rss/terkini.xml',
    ];

    private const KEY = 'ranah:media-eruption-v1';

    public function items(): array
    {
        $cached = Cache::get(self::KEY);
        if (Cache::has(self::KEY.':checked')) {
            return $cached ?? throw new RuntimeException('Sumber berita belum dapat diakses. Coba lagi nanti.');
        }
        $lock = Cache::lock(self::KEY.':lock', 30);
        if (! $lock->get()) {
            return $cached ?? throw new RuntimeException('Berita sedang diperbarui. Coba lagi nanti.');
        }
        try {
            $items = [];
            $successes = 0;
            foreach (self::FEEDS as $url) {
                try {
                    $response = Http::connectTimeout(2)->timeout(4)
                        ->withOptions(['allow_redirects' => false])->get($url)->throw();
                    $items = array_merge($items, $this->parse($response->body()));
                    $successes++;
                } catch (\Throwable) {
                    // Another publisher feed may still be available.
                }
            }
            if ($successes === 0) {
                throw new RuntimeException('RSS berita ANTARA belum dapat diakses. Coba lagi nanti.');
            }
            $items = collect($items)->merge($cached ?? [])->unique('id')
                ->filter(fn ($item) => CarbonImmutable::parse($item['waktu_publikasi'])->isAfter(now()->subDays(30)))
                ->sortByDesc('waktu_publikasi')->take(250)->values()->all();
            Cache::put(self::KEY, $items, now()->addDays(7));
            Cache::put(self::KEY.':checked', true, now()->addMinutes(15));

            return $items;
        } catch (\Throwable $error) {
            Cache::put(self::KEY.':checked', true, now()->addMinute());

            return $cached ?? throw new RuntimeException('Berita ANTARA belum tersedia; tidak diganti dengan laporan gunung.', 0, $error);
        } finally {
            $lock->release();
        }
    }

    public function parse(string $xml): array
    {
        if (strlen($xml) > 5_000_000 || stripos($xml, '<!DOCTYPE') !== false) {
            throw new RuntimeException('RSS tidak valid.');
        }
        $doc = new DOMDocument;
        $previous = libxml_use_internal_errors(true);
        try {
            $valid = $doc->loadXML($xml, LIBXML_NONET);
        } finally {
            libxml_clear_errors();
            libxml_use_internal_errors($previous);
        }
        if (! $valid || $doc->documentElement?->tagName !== 'rss') {
            throw new RuntimeException('Format RSS ANTARA berubah.');
        }
        $xpath = new DOMXPath($doc);
        $items = [];
        foreach ($xpath->query('/rss/channel/item') as $node) {
            $title = $this->text($xpath->evaluate('string(title)', $node));
            $summary = $this->text($xpath->evaluate('string(description)', $node));
            $url = trim($xpath->evaluate('string(link)', $node));
            $parts = parse_url($url);
            if (! is_array($parts) || ($parts['scheme'] ?? '') !== 'https' || isset($parts['user']) || isset($parts['pass'])
                || ! preg_match('/^(?:[a-z0-9-]+\.)?antaranews\.com$/i', $parts['host'] ?? '')
                || ! str_contains($parts['path'] ?? '', '/berita/')) {
                continue;
            }
            $content = $title.' '.$summary;
            if (! preg_match('/\b(erupsi|vulkanik|lahar|awan panas|letusan|pengungsian|pengungsi)\b/iu', $content)
                || ! preg_match('/\b(?:gunung\s+|g\.\s*)?(Anak Krakatau|Sorik Marapi|Ili Lewotolok|Lewotobi(?: Laki-laki)?|Marapi|Merapi|Semeru|Sinabung|Kerinci|Dempo|Kaba|Talang|Tandikat|Krakatau|Slamet|Dieng|Bromo|Raung|Ijen|Agung|Batur|Rinjani|Tambora|Lewotolok|Ibu|Dukono|Gamalama|Karangetang|Ruang|Awu|Soputan|Lokon)\b/iu', $content, $match)) {
                continue;
            }
            // Ambiguous everyday names must explicitly refer to a volcano.
            if (in_array(mb_strtolower($match[1]), ['ibu', 'agung', 'ruang'], true)
                && ! preg_match('/\b(?:gunung\s+|g\.\s*)'.preg_quote($match[1], '/').'\b/iu', $content)) {
                continue;
            }
            try {
                $at = CarbonImmutable::parse(trim($xpath->evaluate('string(pubDate)', $node)));
            } catch (\Throwable) {
                continue;
            }
            if ($title === '' || $summary === '' || trim($xpath->evaluate('string(pubDate)', $node)) === '' || $at->isFuture()) {
                continue;
            }
            // Canonical article path deduplicates cross-feed links and tracking parameters.
            $canonical = 'https://'.strtolower($parts['host']).$parts['path'];
            $id = 'antara-'.hash('sha256', $canonical);
            $image = trim($xpath->evaluate('string(enclosure/@url)', $node));
            if (! preg_match('~^https://(?:[a-z0-9-]+\.)*antaranews\.com/~i', $image)) {
                $image = null;
            }
            $items[$id] = [
                'id' => $id, 'sumber_id' => $id, 'judul' => $title,
                'kategori' => 'Berita Erupsi', 'jenis_konten' => 'artikel',
                'isi' => mb_strimwidth($summary, 0, 400, '…')."\n\nRingkasan dari RSS ANTARA. Baca artikel lengkap melalui tautan sumber.",
                'sumber' => 'ANTARA News', 'url_sumber' => $canonical,
                'gunung' => $match[1], 'wilayah' => null, 'gambar' => $image,
                'waktu_publikasi' => $at->utc()->toIso8601String(),
                'waktu_kejadian' => null, 'waktu_pengambilan' => now()->toIso8601String(),
            ];
        }

        return array_values($items);
    }

    private function text(string $value): string
    {
        return trim(preg_replace('/\s+/u', ' ', strip_tags(html_entity_decode($value, ENT_QUOTES | ENT_HTML5, 'UTF-8'))) ?? '');
    }
}
