<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('contacts', function (Blueprint $table): void {
            $table->id();
            $table->foreignId('user_id')->nullable()->unique()->constrained()->nullOnDelete();
            $table->string('display_name');
            $table->string('contact_type')->default('user')->index();
            $table->string('source')->default('manual')->index();
            $table->string('status')->default('active')->index();
            $table->string('gmail_email')->nullable()->unique();
            $table->string('email')->nullable()->index();
            $table->string('phone')->nullable();
            $table->string('avatar_url')->nullable();
            $table->string('specialty')->nullable();
            $table->string('company_name')->nullable();
            $table->json('tags')->nullable();
            $table->text('internal_note')->nullable();
            $table->timestamp('last_seen_at')->nullable();
            $table->timestamps();
        });

        Schema::create('contact_notes', function (Blueprint $table): void {
            $table->id();
            $table->foreignId('contact_id')->constrained()->cascadeOnDelete();
            $table->foreignId('author_id')->nullable()->constrained('users')->nullOnDelete();
            $table->string('note_type')->default('general')->index();
            $table->text('body');
            $table->timestamps();
        });

        DB::table('users')
            ->orderBy('id')
            ->chunk(100, function ($users): void {
                foreach ($users as $user) {
                    DB::table('contacts')->insert([
                        'user_id' => $user->id,
                        'display_name' => $user->name,
                        'contact_type' => $user->role === 'admin' ? 'internal' : 'user',
                        'source' => $user->google_id ? 'google' : 'system',
                        'status' => 'active',
                        'gmail_email' => $user->google_id ? strtolower($user->email) : null,
                        'email' => strtolower($user->email),
                        'avatar_url' => $user->avatar_url ?? null,
                        'last_seen_at' => now(),
                        'created_at' => now(),
                        'updated_at' => now(),
                    ]);
                }
            });
    }

    public function down(): void
    {
        Schema::dropIfExists('contact_notes');
        Schema::dropIfExists('contacts');
    }
};
