<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('gunung', function (Blueprint $table) {
            $table->string('sumber_validasi_administratif', 180)->nullable();
            $table->string('sumber_validasi_administratif_id', 100)->nullable();
        });

        $records = DB::table('gunung')
            ->where('sumber_koordinat', 'like', '%geoBoundaries%')
            ->get(['id', 'sumber_koordinat_id']);

        foreach ($records as $record) {
            if (! preg_match('/BIG_OBJECTID=(\d+);ADM1_shapeID=([A-Za-z0-9]+)/', $record->sumber_koordinat_id ?? '', $matches)) {
                continue;
            }

            DB::table('gunung')->where('id', $record->id)->update([
                'sumber_koordinat' => 'BIG Atlas Sebaran GunungApi',
                'sumber_koordinat_id' => $matches[1],
                'sumber_validasi_administratif' => 'geoBoundaries IDN ADM1 (2017)',
                'sumber_validasi_administratif_id' => $matches[2],
            ]);
        }
    }

    public function down(): void
    {
        $records = DB::table('gunung')
            ->whereNotNull('sumber_validasi_administratif')
            ->get(['id', 'sumber_koordinat', 'sumber_koordinat_id', 'sumber_validasi_administratif', 'sumber_validasi_administratif_id']);

        foreach ($records as $record) {
            DB::table('gunung')->where('id', $record->id)->update([
                'sumber_koordinat' => $record->sumber_koordinat.' + '.$record->sumber_validasi_administratif,
                'sumber_koordinat_id' => 'BIG_OBJECTID='.$record->sumber_koordinat_id.';ADM1_shapeID='.$record->sumber_validasi_administratif_id,
            ]);
        }

        Schema::table('gunung', function (Blueprint $table) {
            $table->dropColumn(['sumber_validasi_administratif', 'sumber_validasi_administratif_id']);
        });
    }
};
