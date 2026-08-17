<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('ai_training_consents', function (Blueprint $table): void {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->string('consent_type')->default('model_training')->index();
            $table->string('policy_version')->default('2026-07-24');
            $table->boolean('granted')->default(false)->index();
            $table->timestamp('granted_at')->nullable();
            $table->timestamp('revoked_at')->nullable();
            $table->timestamps();

            $table->unique(['user_id', 'consent_type']);
        });

        Schema::create('skin_analysis_images', function (Blueprint $table): void {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->foreignId('skin_analysis_id')->constrained()->cascadeOnDelete();
            $table->string('storage_disk')->default('local');
            $table->string('image_path');
            $table->string('original_filename')->nullable();
            $table->string('mime_type')->nullable();
            $table->unsignedBigInteger('size_bytes')->nullable();
            $table->string('privacy_status')->default('private')->index();
            $table->string('retention_policy')->default('user_history');
            $table->timestamp('deleted_at')->nullable();
            $table->timestamps();

            $table->index(['user_id', 'created_at']);
        });

        Schema::create('model_training_samples', function (Blueprint $table): void {
            $table->id();
            $table->foreignId('user_id')->nullable()->constrained()->nullOnDelete();
            $table->foreignId('skin_analysis_id')->constrained()->cascadeOnDelete();
            $table->foreignId('skin_analysis_image_id')->constrained()->cascadeOnDelete();
            $table->foreignId('ai_training_consent_id')->constrained('ai_training_consents')->cascadeOnDelete();
            $table->string('label_source')->default('ai')->index();
            $table->string('review_status')->default('pending')->index();
            $table->string('training_status')->default('queued')->index();
            $table->json('snapshot_payload');
            $table->json('anonymized_metadata')->nullable();
            $table->timestamp('reviewed_at')->nullable();
            $table->timestamp('exported_at')->nullable();
            $table->timestamps();
        });

        Schema::create('model_versions', function (Blueprint $table): void {
            $table->id();
            $table->string('name')->index();
            $table->string('version')->index();
            $table->string('status')->default('candidate')->index();
            $table->json('metrics')->nullable();
            $table->json('dataset_snapshot')->nullable();
            $table->timestamp('trained_at')->nullable();
            $table->timestamp('deployed_at')->nullable();
            $table->timestamps();

            $table->unique(['name', 'version']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('model_versions');
        Schema::dropIfExists('model_training_samples');
        Schema::dropIfExists('skin_analysis_images');
        Schema::dropIfExists('ai_training_consents');
    }
};
