<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Berita extends Model
{
    protected $table = 'berita';

    protected $fillable = [
        'judul',
        'kategori',
        'isi',
        'gambar',
        'sumber',
        'waktu_publikasi',
        'status_publikasi',
    ];

    protected function casts(): array
    {
        return [
            'waktu_publikasi' => 'datetime',
        ];
    }
}
