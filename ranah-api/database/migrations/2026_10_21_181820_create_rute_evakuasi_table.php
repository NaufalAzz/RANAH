
<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('rute_evakuasi', function (Blueprint $table) {
            $table->id();

            $table->string('nama', 150);

            $table->foreignId('titik_awal_id')
                ->constrained('titik_evakuasi')
                ->restrictOnDelete();

            $table->foreignId('titik_tujuan_id')
                ->constrained('titik_evakuasi')
                ->restrictOnDelete();

            $table->string('jenis_bencana', 50);
            $table->json('geometri');

            $table->decimal('jarak_km', 8, 2)->nullable();
            $table->unsignedSmallInteger('estimasi_menit')->nullable();

            $table->dateTime('terverifikasi_pada')->nullable();
            $table->boolean('aktif')->default(true);

            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('rute_evakuasi');
    }
};
