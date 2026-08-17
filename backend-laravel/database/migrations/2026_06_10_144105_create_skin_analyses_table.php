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
        Schema::create('skin_analyses', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->string('image_path');
            $table->string('skin_type_slug')->nullable()->index();
            $table->decimal('skin_type_confidence', 5, 4)->nullable();
            $table->json('concerns')->nullable();
            $table->unsignedTinyInteger('skin_health_score')->nullable();
            $table->string('ai_provider')->default('skin-ai-service');
            $table->json('raw_result')->nullable();
            $table->timestamps();

            $table->index(['user_id', 'created_at']);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('skin_analyses');
    }
};
