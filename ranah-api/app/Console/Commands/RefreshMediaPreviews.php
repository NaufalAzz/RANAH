<?php

namespace App\Console\Commands;

use App\Services\MediaEruptionFeed;
use Illuminate\Console\Command;

class RefreshMediaPreviews extends Command
{
    protected $signature = 'ranah:refresh-news-previews';

    protected $description = 'Perbarui metadata berita di luar permintaan API';

    public function handle(MediaEruptionFeed $feed): int
    {
        if (! config('services.media_news.previews', true)) {
            $this->info('Pengambilan metadata dinonaktifkan.');

            return self::SUCCESS;
        }
        $counts = $feed->warmPreviews();
        $this->info('Artikel di cache: '.$counts['articles']);
        $this->info('Isi artikel ditemukan: '.$counts['bodies']);
        $this->info('URL sampul tersedia: '.$counts['images']);
        if ($counts['bodies'] === 0) {
            $this->warn('Isi artikel belum berhasil diambil; batch selesai tidak berarti pengambilan berhasil.');
        }

        return self::SUCCESS;
    }
}
