<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('gunung', function (Blueprint $table) {
            $table->string('sumber_id', 100)->nullable()->unique();
            $table->dateTime('waktu_pengambilan')->nullable();
        });

        Schema::table('laporan_gunung', function (Blueprint $table) {
            $table->string('sumber_id', 100)->nullable();
            $table->string('url_sumber', 2048)->nullable();
            $table->string('periode_waktu', 100)->nullable();
            $table->dateTime('waktu_pengambilan')->nullable();
            $table->unique(['sumber', 'sumber_id'], 'laporan_gunung_source_id_unique');
        });
    }

    public function down(): void
    {
        Schema::table('laporan_gunung', function (Blueprint $table) {
            $table->dropUnique('laporan_gunung_source_id_unique');
            $table->dropColumn(['sumber_id', 'url_sumber', 'periode_waktu', 'waktu_pengambilan']);
        });

        Schema::table('gunung', function (Blueprint $table) {
            $table->dropUnique(['sumber_id']);
            $table->dropColumn(['sumber_id', 'waktu_pengambilan']);
        });
    }
};
