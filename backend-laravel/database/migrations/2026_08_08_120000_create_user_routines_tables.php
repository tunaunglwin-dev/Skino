<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('user_routines', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->foreignId('skin_analysis_id')->constrained()->cascadeOnDelete();
            $table->json('routine_payload');
            $table->boolean('is_active')->default(true);
            $table->timestamp('started_at');
            $table->timestamps();

            $table->index(['user_id', 'is_active']);
        });

        Schema::create('routine_check_ins', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_routine_id')->constrained()->cascadeOnDelete();
            $table->date('check_date');
            $table->boolean('morning_done')->default(false);
            $table->boolean('night_done')->default(false);
            $table->timestamp('morning_completed_at')->nullable();
            $table->timestamp('night_completed_at')->nullable();
            $table->timestamps();

            $table->unique(['user_routine_id', 'check_date']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('routine_check_ins');
        Schema::dropIfExists('user_routines');
    }
};
