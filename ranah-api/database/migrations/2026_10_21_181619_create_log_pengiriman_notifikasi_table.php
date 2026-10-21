
<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('log_pengiriman_notifikasi', function (Blueprint $table) {
            $table->id();

            $table->foreignId('notifikasi_id')
                ->constrained('notifikasi')
                ->restrictOnDelete();

            $table->string('tujuan', 255);
            $table->string('status_pengiriman', 30);
            $table->string('id_pesan_fcm', 255)->nullable();
            $table->text('pesan_kesalahan')->nullable();
            $table->dateTime('waktu_pengiriman')->nullable();

            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('log_pengiriman_notifikasi');
    }
};
