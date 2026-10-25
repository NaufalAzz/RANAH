<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('gunung', function (Blueprint $table) {
            $table->string('sumber_koordinat', 120)->nullable();
            $table->string('sumber_koordinat_id', 100)->nullable();
            $table->string('status_validasi_koordinat', 30)->nullable();
            $table->dateTime('waktu_validasi_koordinat')->nullable();
        });
    }

    public function down(): void
    {
        Schema::table('gunung', function (Blueprint $table) {
            $table->dropColumn([
                'sumber_koordinat',
                'sumber_koordinat_id',
                'status_validasi_koordinat',
                'waktu_validasi_koordinat',
            ]);
        });
    }
};
