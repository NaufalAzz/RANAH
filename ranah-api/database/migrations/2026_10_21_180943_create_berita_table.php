
<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('berita', function (Blueprint $table) {
            $table->id();

            $table->string('judul', 200);
            $table->string('kategori', 50);
            $table->longText('isi');

            $table->string('gambar', 255)->nullable();
            $table->string('sumber', 255)->nullable();

            $table->dateTime('waktu_publikasi')->nullable();
            $table->string('status_publikasi', 20)->default('draft');

            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('berita');
    }
};
