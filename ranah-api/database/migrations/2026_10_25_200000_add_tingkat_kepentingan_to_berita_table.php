<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (! Schema::hasColumn('berita', 'tingkat_kepentingan')) {
            Schema::table('berita', function (Blueprint $table): void {
                $table->string('tingkat_kepentingan', 30)->nullable();
            });
        }
    }

    public function down(): void
    {
        if (Schema::hasColumn('berita', 'tingkat_kepentingan')) {
            Schema::table('berita', function (Blueprint $table): void {
                $table->dropColumn('tingkat_kepentingan');
            });
        }
    }
};
