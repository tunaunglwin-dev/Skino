<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('crm_records', function (Blueprint $table): void {
            $table->id();
            $table->foreignId('contact_id')->constrained()->cascadeOnDelete();
            $table->foreignId('specialist_contact_id')->nullable()->constrained('contacts')->nullOnDelete();
            $table->foreignId('owner_id')->nullable()->constrained('users')->nullOnDelete();
            $table->string('title');
            $table->string('stage')->default('new')->index();
            $table->string('priority')->default('normal')->index();
            $table->string('source')->default('admin')->index();
            $table->string('appointment_status')->default('not_scheduled')->index();
            $table->timestamp('scheduled_at')->nullable()->index();
            $table->string('beauty_goal')->nullable();
            $table->text('concern_summary')->nullable();
            $table->json('tags')->nullable();
            $table->timestamps();

            $table->index(['stage', 'scheduled_at']);
        });

        Schema::create('crm_notes', function (Blueprint $table): void {
            $table->id();
            $table->foreignId('crm_record_id')->constrained()->cascadeOnDelete();
            $table->foreignId('author_id')->nullable()->constrained('users')->nullOnDelete();
            $table->string('note_type')->default('general')->index();
            $table->text('body');
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('crm_notes');
        Schema::dropIfExists('crm_records');
    }
};
