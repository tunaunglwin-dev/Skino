<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('model_training_samples', function (Blueprint $table): void {
            $table->foreignId('reviewed_by_id')->nullable()->after('anonymized_metadata')->constrained('users')->nullOnDelete();
            $table->json('corrected_labels')->nullable()->after('reviewed_by_id');
            $table->text('review_note')->nullable()->after('corrected_labels');
        });
    }

    public function down(): void
    {
        Schema::table('model_training_samples', function (Blueprint $table): void {
            $table->dropConstrainedForeignId('reviewed_by_id');
            $table->dropColumn(['corrected_labels', 'review_note']);
        });
    }
};
