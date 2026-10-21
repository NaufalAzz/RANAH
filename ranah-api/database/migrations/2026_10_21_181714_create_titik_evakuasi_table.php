
<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('titik_evakuasi', function (Blueprint $table) {
            $table->id();

            $table->string('nama', 150);
            $table->string('jenis', 50);
            $table->string('alamat', 255)->nullable();

            $table->decimal('latitude', 10, 7);
            $table->decimal('longitude', 10, 7);

            $table->dateTime('terverifikasi_pada')->nullable();
            $table->boolean('aktif')->default(true);

            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('titik_evakuasi');
    }
};
