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
        $feed->warmPreviews();
        $this->info('Batch metadata berita selesai.');

        return self::SUCCESS;
    }
}
