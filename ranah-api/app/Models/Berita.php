<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Berita extends Model
{
    protected $table = 'berita';

    protected $fillable = [
        'judul',
        'kategori',
        'jenis_konten',
        'isi',
        'gambar',
        'sumber',
        'sumber_id',
        'url_sumber',
        'wilayah',
        'waktu_publikasi',
        'waktu_kejadian',
        'waktu_berakhir',
        'waktu_pengambilan',
        'status_publikasi',
    ];

    protected function casts(): array
    {
        return [
            'waktu_publikasi' => 'datetime',
            'waktu_kejadian' => 'datetime',
            'waktu_berakhir' => 'datetime',
            'waktu_pengambilan' => 'datetime',
        ];
    }
}
