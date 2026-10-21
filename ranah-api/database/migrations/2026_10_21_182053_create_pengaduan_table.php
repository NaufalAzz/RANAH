
<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('pengaduan', function (Blueprint $table) {
            $table->id();

            $table->string('nama_pelapor', 150);
            $table->string('nomor_telepon', 30);
            $table->string('kategori', 50);

            $table->string('lokasi_kejadian', 255);
            $table->decimal('latitude', 10, 7)->nullable();
            $table->decimal('longitude', 10, 7)->nullable();

            $table->text('deskripsi');
            $table->json('media')->nullable();

            $table->dateTime('waktu_pengaduan');

            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('pengaduan');
    }
};
