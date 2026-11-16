<?php

namespace App\Services;

use Carbon\CarbonImmutable;
use DOMDocument;
use DOMXPath;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Http;
use RuntimeException;

class MagmaEruptionFeed
{
    public const URL = 'https://magma.esdm.go.id/v1/gunung-api/informasi-letusan';

    public function items(): array
    {
        $cached = Cache::get('magma:eruption-feed');
        if (Cache::has('magma:eruption-checked')) {
            return $cached ?? throw new RuntimeException('Laporan MAGMA belum tersedia. Coba lagi nanti.');
        }
        $lock = Cache::lock('magma:eruption-refresh', 30);
        if (! $lock->get()) {
            return $cached ?? throw new RuntimeException('Laporan MAGMA belum tersedia. Coba lagi nanti.');
        }
        try {
            $response = Http::connectTimeout(5)->timeout(15)->withOptions(['allow_redirects' => false])->get(self::URL)->throw();
            $items = $this->parse($response->body());
            if ($items === []) {
                throw new RuntimeException('Daftar erupsi MAGMA belum dapat dibaca.');
            }
            $items = collect($items)->merge($cached ?? [])->unique('id')
                ->filter(fn ($item) => CarbonImmutable::parse($item['waktu_kejadian'])->isAfter(now()->subDays(30)))
                ->sortByDesc('waktu_kejadian')->take(250)->values()->all();
            Cache::put('magma:eruption-feed', $items, now()->addDays(7));
            Cache::put('magma:eruption-checked', true, now()->addMinutes(15));

            return $items;
        } catch (\Throwable $error) {
            Cache::put('magma:eruption-checked', true, now()->addMinute());
            if ($cached !== null) {
                return $cached;
            }
            throw new RuntimeException('Laporan MAGMA belum tersedia. Coba lagi nanti.', 0, $error);
        } finally {
            $lock->release();
        }
    }

    public function parse(string $html): array
    {
        $doc = new DOMDocument;
        $previous = libxml_use_internal_errors(true);
        try {
            $doc->loadHTML('<?xml encoding="UTF-8">'.$html, LIBXML_NONET);
        } finally {
            libxml_clear_errors();
            libxml_use_internal_errors($previous);
        }
        $xpath = new DOMXPath($doc);
        $items = [];
        $months = ['Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni', 'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'];
        foreach ($xpath->query('//*[contains(concat(" ", normalize-space(@class), " "), " timeline-item ")]') as $node) {
            $name = trim($xpath->evaluate('string(.//*[contains(@class,"timeline-title")])', $node));
            $text = trim(preg_replace('/\s+/u', ' ', $xpath->evaluate('string(.//*[contains(@class,"timeline-text")])', $node)) ?? '');
            $url = $xpath->evaluate('string(.//a[contains(@href,"/show")]/@href)', $node);
            if (! preg_match('~^https://magma\.esdm\.go\.id/v1/gunung-api/informasi-letusan/([a-f0-9-]+)/show$~', $url, $id) || $name === '') {
                continue;
            }
            if (! preg_match('/(\d{1,2}) ('.implode('|', $months).') (\d{4}),?\s+pukul (\d{2}:\d{2})(?::(\d{2}))? (WIB|WITA|WIT)/u', $text, $date)) {
                continue;
            }
            $month = array_search($date[2], $months, true) + 1;
            $zone = ['WIB' => 'Asia/Jakarta', 'WITA' => 'Asia/Makassar', 'WIT' => 'Asia/Jayapura'][$date[6]];
            $at = CarbonImmutable::createFromFormat('!Y-n-j H:i:s', "$date[3]-$month-$date[1] $date[4]:".($date[5] ?: '00'), $zone);
            if (! $at || $at->isFuture()) {
                continue;
            }
            $items[$id[1]] = ['id' => 'magma-'.$id[1], 'judul' => 'Laporan erupsi Gunung '.$name, 'kategori' => 'Erupsi', 'jenis_konten' => 'kejadian', 'isi' => 'MAGMA/PVMBG mencatat laporan erupsi Gunung '.$name.'. Buka sumber resmi untuk rincian kejadian dan rekomendasi terbaru.', 'sumber' => 'MAGMA Indonesia / PVMBG', 'sumber_id' => $id[1], 'url_sumber' => $url, 'gunung' => $name, 'wilayah' => null, 'gambar' => null, 'waktu_publikasi' => $at->toIso8601String(), 'waktu_kejadian' => $at->toIso8601String(), 'waktu_pengambilan' => now()->toIso8601String()];
        }
        $items = array_values($items);
        usort($items, fn ($a, $b) => strcmp($b['waktu_publikasi'], $a['waktu_publikasi']));

        return $items;
    }
}
