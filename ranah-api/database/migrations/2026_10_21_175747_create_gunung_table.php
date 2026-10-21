
<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::create('gunung', function (Blueprint $table) {
            $table->id();

            $table->string('nama', 150);
            $table->string('provinsi', 100);
            $table->string('kabupaten', 150)->nullable();

            $table->decimal('latitude', 10, 7)->nullable();
            $table->decimal('longitude', 10, 7)->nullable();

            $table->string('status_aktivitas', 50)->nullable();
            $table->decimal('radius_perkiraan_km', 8, 2)->nullable();

            $table->string('sumber_data', 255)->nullable();
            $table->boolean('aktif')->default(true);

            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('gunung');
    }
};
