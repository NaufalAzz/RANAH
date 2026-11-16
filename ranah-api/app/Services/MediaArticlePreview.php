<?php

namespace App\Services;

use DOMDocument;
use DOMXPath;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Http;

/** Only publisher previews and cover metadata; full articles stay on the publisher site. */
class MediaArticlePreview
{
    private const HOSTS = ['antaranews.com', 'kompas.com', 'detik.com', 'tempo.co', 'cnnindonesia.com', 'rri.co.id', 'mediaindonesia.com'];

    public function apply(array $item): array
    {
        $preview = Cache::get('media-preview:'.hash('sha256', $item['url_sumber']));
        if (! is_array($preview)) {
            return $item;
        }
        if (isset($preview['description']) && is_string($preview['description']) && $preview['description'] !== '') {
            $item['isi'] = $preview['description']."\n\nPratinjau dari penerbit. Baca penjelasan lengkap melalui tautan sumber.";
        }
        if (isset($preview['image']) && is_string($preview['image']) && $preview['image'] !== '') {
            $item['gambar'] = $preview['image'];
        }
        if (isset($preview['url']) && is_string($preview['url']) && $preview['url'] !== '') {
            $item['url_sumber'] = $preview['url'];
        }

        return $item;
    }

    public function warm(array $items): void
    {
        $started = microtime(true);
        foreach (array_slice($items, 0, 12) as $item) {
            if (microtime(true) - $started > 5) {
                break;
            }
            $key = 'media-preview:'.hash('sha256', $item['url_sumber']);
            if (Cache::has($key)) {
                continue;
            }
            try {
                $url = $item['url_sumber'];
                $preview = [];
                for ($hop = 0; $hop < 3; $hop++) {
                    if (! $this->safe($url, [...self::HOSTS, 'news.google.com'])) {
                        break;
                    }
                    $response = Http::connectTimeout(1)->timeout(2)->withOptions(['allow_redirects' => false])->get($url);
                    if ($response->redirect()) {
                        $next = $response->header('Location');
                        if (! is_string($next) || ! str_starts_with($next, 'https://')) {
                            break;
                        }
                        $url = $next;

                        continue;
                    }
                    if (! $response->successful() || strlen($response->body()) > 2_000_000) {
                        break;
                    }
                    if (! $this->safe($url, self::HOSTS)) {
                        // Some Google index pages expose the original publisher URL.
                        preg_match('/data-n-au=["\']([^"\']+)["\']/i', $response->body(), $match);
                        $url = html_entity_decode($match[1] ?? '', ENT_QUOTES | ENT_HTML5, 'UTF-8');

                        continue;
                    }
                    $preview = $this->parse($response->body(), $url);
                    break;
                }
                Cache::put($key, $preview, now()->addHours($preview === [] ? 1 : 24));
            } catch (\Throwable) {
                Cache::put($key, [], now()->addHour());
            }
        }
    }

    public function parse(string $html, string $url): array
    {
        if (! $this->safe($url, self::HOSTS)) {
            return [];
        }
        $doc = new DOMDocument;
        $previous = libxml_use_internal_errors(true);
        try {
            $doc->loadHTML('<?xml encoding="UTF-8">'.$html, LIBXML_NONET);
        } finally {
            libxml_clear_errors();
            libxml_use_internal_errors($previous);
        }
        $xpath = new DOMXPath($doc);
        $meta = [];
        foreach ($xpath->query('//meta[@content]') as $node) {
            $name = strtolower($node->getAttribute('property') ?: $node->getAttribute('name'));
            $meta[$name] ??= $node->getAttribute('content');
        }
        $description = trim(preg_replace('/\s+/u', ' ', strip_tags(html_entity_decode($meta['og:description'] ?? $meta['description'] ?? '', ENT_QUOTES | ENT_HTML5, 'UTF-8'))) ?? '');
        $description = implode(' ', array_slice(preg_split('/\s+/u', $description) ?: [], 0, 75));
        $image = $meta['og:image:secure_url'] ?? $meta['og:image'] ?? $meta['twitter:image'] ?? null;
        if (is_string($image) && str_starts_with($image, '/')) {
            $image = 'https://'.parse_url($url, PHP_URL_HOST).$image;
        }
        if (! is_string($image) || ! $this->safe($image, [...self::HOSTS, 'detik.net.id', 'kompas.tv', 'tstatic.net'])) {
            $image = null;
        }

        return ['description' => $description, 'image' => $image, 'url' => $url];
    }

    private function safe(string $url, array $hosts): bool
    {
        $parts = parse_url($url);
        if (! is_array($parts) || ($parts['scheme'] ?? '') !== 'https' || isset($parts['user']) || isset($parts['pass']) || isset($parts['port'])) {
            return false;
        }
        $host = strtolower($parts['host'] ?? '');
        foreach ($hosts as $allowed) {
            if ($host === $allowed || str_ends_with($host, '.'.$allowed)) {
                return true;
            }
        }

        return false;
    }
}
