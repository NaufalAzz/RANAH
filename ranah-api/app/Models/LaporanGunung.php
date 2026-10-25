<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class LaporanGunung extends Model
{
    protected $table = 'laporan_gunung';

    protected $fillable = [
        'gunung_id',
        'periode_mulai',
        'periode_selesai',
        'data_klimatologi',
        'pengamatan_visual',
        'rekomendasi',
        'foto',
        'sumber',
        'waktu_publikasi',
        'periode_waktu',
        'url_sumber',
        'sumber_id',
        'waktu_pengambilan',
    ];

    protected function casts(): array
    {
        return [
            'periode_mulai' => 'date',
            'periode_selesai' => 'date',
            'waktu_publikasi' => 'datetime',
            'waktu_pengambilan' => 'datetime',
        ];
    }

    public function gunung(): BelongsTo
    {
        return $this->belongsTo(Gunung::class, 'gunung_id');
    }
}
