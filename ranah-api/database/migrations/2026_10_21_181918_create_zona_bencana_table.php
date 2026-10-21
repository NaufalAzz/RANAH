
<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('zona_bencana', function (Blueprint $table) {
            $table->id();

            $table->string('nama', 150);
            $table->string('jenis_bencana', 50);
            $table->json('geometri');

            $table->string('sumber_data', 255);
            $table->text('keterangan')->nullable();
            $table->dateTime('diperbarui_pada')->nullable();

            $table->boolean('aktif')->default(true);

            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('zona_bencana');
    }
};
