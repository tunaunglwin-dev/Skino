<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('routine_check_ins', function (Blueprint $table) {
            $table->json('morning_steps')->nullable()->after('morning_done');
            $table->json('night_steps')->nullable()->after('night_done');
        });
    }

    public function down(): void
    {
        Schema::table('routine_check_ins', function (Blueprint $table) {
            $table->dropColumn(['morning_steps', 'night_steps']);
        });
    }
};
