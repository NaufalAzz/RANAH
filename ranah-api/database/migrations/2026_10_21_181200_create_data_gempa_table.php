
<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('data_gempa', function (Blueprint $table) {
            $table->id();

            $table->string('id_bmkg', 100)->unique();
            $table->decimal('magnitudo', 4, 1)->nullable();
            $table->decimal('kedalaman_km', 7, 2)->nullable();

            $table->string('lokasi', 255);
            $table->decimal('latitude', 10, 7)->nullable();
            $table->decimal('longitude', 10, 7)->nullable();

            $table->dateTime('waktu_gempa');
            $table->string('sumber_data', 100)->default('BMKG');
            $table->json('data_asli')->nullable();

            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('data_gempa');
    }
};
