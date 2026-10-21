
<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('langkah_mitigasi', function (Blueprint $table) {
            $table->id();

            $table->foreignId('kategori_mitigasi_id')
                ->constrained('kategori_mitigasi')
                ->restrictOnDelete();

            $table->string('judul', 200);
            $table->text('isi');
            $table->unsignedSmallInteger('urutan');

            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('langkah_mitigasi');
    }
};
