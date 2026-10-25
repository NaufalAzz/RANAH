<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Pengaduan extends Model
{
    protected $table = 'pengaduan';

    protected $fillable = [
        'nama_pelapor',
        'nomor_telepon',
        'kategori',
        'lokasi_kejadian',
        'latitude',
        'longitude',
        'deskripsi',
        'media',
        'waktu_pengaduan',
    ];

    protected $hidden = [
        'nama_pelapor',
        'nomor_telepon',
        'lokasi_kejadian',
        'latitude',
        'longitude',
        'deskripsi',
        'media',
    ];

    protected function casts(): array
    {
        return [
            'media' => 'array',
            'waktu_pengaduan' => 'datetime',
        ];
    }
}
