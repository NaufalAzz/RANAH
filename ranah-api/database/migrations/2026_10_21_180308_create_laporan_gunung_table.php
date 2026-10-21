
<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('laporan_gunung', function (Blueprint $table) {
            $table->id();

            $table->foreignId('gunung_id')
                ->constrained('gunung')
                ->restrictOnDelete();

            $table->date('periode_mulai')->nullable();
            $table->date('periode_selesai')->nullable();

            $table->text('data_klimatologi')->nullable();
            $table->text('pengamatan_visual')->nullable();
            $table->text('rekomendasi')->nullable();

            $table->string('foto', 255)->nullable();
            $table->string('sumber', 255);
            $table->dateTime('waktu_publikasi')->nullable();

            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('laporan_gunung');
    }
};
