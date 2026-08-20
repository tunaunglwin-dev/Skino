<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('users', function (Blueprint $table): void {
            $table->string('age_band')->nullable()->after('avatar_url');
            $table->unsignedTinyInteger('skin_tone_scale')->nullable()->after('age_band');
            $table->json('skin_goals')->nullable()->after('skin_tone_scale');
            $table->timestamp('profile_completed_at')->nullable()->after('skin_goals');
        });
    }

    public function down(): void
    {
        Schema::table('users', function (Blueprint $table): void {
            $table->dropColumn(['age_band', 'skin_tone_scale', 'skin_goals', 'profile_completed_at']);
        });
    }
};
