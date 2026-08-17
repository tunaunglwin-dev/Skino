<?php

namespace Database\Seeders;

use App\Enums\UserRole;
use App\Models\User;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Validator;
use Illuminate\Validation\Rules\Password;

class AdminUserSeeder extends Seeder
{
    public function run(): void
    {
        if (! config('admin.seed.enabled')) {
            return;
        }

        $email = (string) config('admin.seed.email');
        $password = (string) config('admin.seed.password');

        if ($email === '' || $password === '') {
            return;
        }

        Validator::make(
            ['email' => $email, 'password' => $password],
            [
                'email' => ['required', 'email:rfc', 'max:255'],
                'password' => ['required', Password::min(10)->mixedCase()->numbers()->symbols()],
            ],
        )->validate();

        $normalizedEmail = strtolower($email);
        $existing = User::query()->where('email', $normalizedEmail)->first();

        if ($existing && ! config('admin.seed.update_existing')) {
            return;
        }

        User::query()->updateOrCreate(
            ['email' => $normalizedEmail],
            [
                'name' => (string) config('admin.seed.name', 'Platform Admin'),
                'password' => Hash::make($password),
                'role' => UserRole::Admin,
            ],
        );
    }
}
