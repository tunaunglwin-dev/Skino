<?php

namespace Database\Seeders;

use App\Models\SkinConcern;
use Illuminate\Database\Seeder;

class SkinConcernSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        $concerns = [
            ['slug' => 'acne', 'name' => 'Acne', 'description' => 'Visible breakouts, pimples, or clogged pores.', 'sort_order' => 10],
            ['slug' => 'dark_spots', 'name' => 'Dark Spots', 'description' => 'Visible uneven pigmentation or post-acne marks.', 'sort_order' => 20],
            ['slug' => 'redness', 'name' => 'Redness', 'description' => 'Visible redness or irritated-looking areas.', 'sort_order' => 30],
            ['slug' => 'dryness', 'name' => 'Dryness', 'description' => 'Visible dry patches, flaking, or dehydration signs.', 'sort_order' => 40],
            ['slug' => 'oiliness', 'name' => 'Oiliness', 'description' => 'Visible shine or excess oil appearance.', 'sort_order' => 50],
            ['slug' => 'texture', 'name' => 'Texture', 'description' => 'Uneven skin texture or rough-looking areas.', 'sort_order' => 60],
        ];

        foreach ($concerns as $concern) {
            SkinConcern::query()->updateOrCreate(
                ['slug' => $concern['slug']],
                $concern + ['is_active' => true],
            );
        }
    }
}
