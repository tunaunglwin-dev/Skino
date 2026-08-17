<?php

namespace Database\Seeders;

use App\Models\SkinType;
use Illuminate\Database\Seeder;

class SkinTypeSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        $skinTypes = [
            ['slug' => 'oily', 'name' => 'Oily', 'description' => 'Skin that tends to produce excess sebum and shine.', 'sort_order' => 10],
            ['slug' => 'dry', 'name' => 'Dry', 'description' => 'Skin that may feel tight, flaky, or rough.', 'sort_order' => 20],
            ['slug' => 'combination', 'name' => 'Combination', 'description' => 'Skin with oily and dry areas, often oily in the T-zone.', 'sort_order' => 30],
            ['slug' => 'sensitive', 'name' => 'Sensitive', 'description' => 'Skin that may react easily to products or environmental changes.', 'sort_order' => 40],
            ['slug' => 'normal', 'name' => 'Normal', 'description' => 'Balanced skin with few visible concerns.', 'sort_order' => 50],
        ];

        foreach ($skinTypes as $skinType) {
            SkinType::query()->updateOrCreate(
                ['slug' => $skinType['slug']],
                $skinType + ['is_active' => true],
            );
        }
    }
}
