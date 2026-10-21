<?php

namespace App\Models;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\Model;

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
        'aktif',
    ];

    public function laporan(): HasMany
{
    return $this->hasMany(LaporanGunung::class, 'gunung_id');
}
}
