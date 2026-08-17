<?php

namespace Database\Seeders;

use App\Models\User;
use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;

class DatabaseSeeder extends Seeder
{
    use WithoutModelEvents;

    /**
     * Seed the application's database.
     */
    public function run(): void
    {
        $this->call([
            ProductCategorySeeder::class,
            SkinTypeSeeder::class,
            SkinConcernSeeder::class,
            ProductSeeder::class,
            AdminUserSeeder::class,
        ]);

        User::query()->updateOrCreate(
            ['email' => 'user@skin-ai.test'],
            ['name' => 'Mobile User', 'password' => 'Password123'],
        );
    }
}
