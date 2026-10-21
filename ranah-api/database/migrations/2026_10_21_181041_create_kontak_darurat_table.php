
<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('kontak_darurat', function (Blueprint $table) {
            $table->id();

            $table->string('nama_layanan', 150);
            $table->string('nomor_telepon', 30);
            $table->string('kategori', 50)->nullable();

            $table->unsignedSmallInteger('urutan')->default(0);
            $table->boolean('aktif')->default(true);

            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('kontak_darurat');
    }
};
