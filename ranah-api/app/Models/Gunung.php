<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Gunung extends Model
{
    protected $table = 'gunung';

    protected $fillable = [
        'nama',
        'provinsi',
        'kabupaten',
        'latitude',
        'longitude',
        'status_aktivitas',
        'radius_perkiraan_km',
        'sumber_data',
        'sumber_id',
        'waktu_pengambilan',
        'sumber_koordinat',
        'sumber_koordinat_id',
        'sumber_validasi_administratif',
        'sumber_validasi_administratif_id',
        'status_validasi_koordinat',
        'waktu_validasi_koordinat',
        'aktif',
    ];

    public function laporan(): HasMany
    {
        return $this->hasMany(LaporanGunung::class, 'gunung_id');
    }

    protected function casts(): array
    {
        return [
            'waktu_pengambilan' => 'datetime',
            'waktu_validasi_koordinat' => 'datetime',
        ];
    }
}
