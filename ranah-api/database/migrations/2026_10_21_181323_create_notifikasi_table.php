
<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('notifikasi', function (Blueprint $table) {
            $table->id();

            $table->string('judul', 200);
            $table->text('isi');
            $table->string('jenis_bencana', 50);
            $table->string('tingkat_keparahan', 30)->nullable();
            $table->string('wilayah_tujuan', 150)->nullable();
            $table->string('topik_fcm', 150)->nullable();

            $table->foreignId('data_gempa_id')
                ->nullable()
                ->constrained('data_gempa')
                ->restrictOnDelete();

            $table->foreignId('laporan_gunung_id')
                ->nullable()
                ->constrained('laporan_gunung')
                ->restrictOnDelete();

            $table->dateTime('waktu_publikasi')->nullable();
            $table->string('status', 20)->default('draft');

            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('notifikasi');
    }
};
