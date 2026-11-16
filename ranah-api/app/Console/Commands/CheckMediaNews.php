<?php

namespace App\Console\Commands;

use App\Services\MediaEruptionFeed;
use Illuminate\Console\Command;
use Illuminate\Support\Facades\Http;

class CheckMediaNews extends Command
{
    protected $signature = 'ranah:check-news';

    protected $description = 'Periksa koneksi feed artikel media dan jumlah artikel erupsi tanpa mengubah cache';

    public function handle(MediaEruptionFeed $feed): int
    {
        $found = 0;
        foreach ([...MediaEruptionFeed::FEEDS, MediaEruptionFeed::SEARCH_URL] as $url) {
            try {
                $response = Http::connectTimeout(2)->timeout(3)->withOptions(['allow_redirects' => false])->get($url);
                if (! $response->successful()) {
                    $this->warn($url.' → HTTP '.$response->status());

                    continue;
                }
                $count = count($feed->parse($response->body(), $url === MediaEruptionFeed::SEARCH_URL));
                $found += $count;
                $this->line($url.' → HTTP '.$response->status().', artikel erupsi: '.$count);
            } catch (\Throwable $error) {
                $this->warn($url.' → koneksi atau format feed gagal ('.$error::class.')');
            }
        }
        if ($found === 0) {
            $this->warn('Belum ada artikel yang dapat digunakan dari sumber yang diperiksa.');
        }

        return $found > 0 ? self::SUCCESS : self::FAILURE;
    }
}
