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
        Schema::table('berita', function (Blueprint $table) {
            $table->string('jenis_konten', 20)->default('artikel')->after('kategori');
            $table->string('sumber_id', 100)->nullable()->unique()->after('sumber');
            $table->text('url_sumber')->nullable()->after('sumber_id');
            $table->string('wilayah', 255)->nullable()->after('url_sumber');
            $table->dateTime('waktu_kejadian')->nullable()->after('waktu_publikasi');
            $table->dateTime('waktu_berakhir')->nullable()->after('waktu_kejadian');
            $table->dateTime('waktu_pengambilan')->nullable()->after('waktu_berakhir');
            $table->index(['jenis_konten', 'status_publikasi', 'waktu_berakhir']);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('berita', function (Blueprint $table) {
            $table->dropIndex(['jenis_konten', 'status_publikasi', 'waktu_berakhir']);
            $table->dropUnique(['sumber_id']);
            $table->dropColumn([
                'jenis_konten',
                'sumber_id',
                'url_sumber',
                'wilayah',
                'waktu_kejadian',
                'waktu_berakhir',
                'waktu_pengambilan',
            ]);
        });
    }
};
