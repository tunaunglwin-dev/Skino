<?php

namespace Database\Seeders;

use App\Models\ProductCategory;
use Illuminate\Database\Seeder;

class ProductCategorySeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        $categories = [
            ['slug' => 'cleanser', 'name' => 'Cleanser', 'description' => 'Products used to cleanse the skin.', 'sort_order' => 10],
            ['slug' => 'toner', 'name' => 'Toner', 'description' => 'Lightweight products used after cleansing.', 'sort_order' => 20],
            ['slug' => 'serum', 'name' => 'Serum', 'description' => 'Targeted treatment products.', 'sort_order' => 30],
            ['slug' => 'moisturizer', 'name' => 'Moisturizer', 'description' => 'Products used to support skin hydration.', 'sort_order' => 40],
            ['slug' => 'sunscreen', 'name' => 'Sunscreen', 'description' => 'Products used for daytime UV protection.', 'sort_order' => 50],
        ];

        foreach ($categories as $category) {
            ProductCategory::query()->updateOrCreate(
                ['slug' => $category['slug']],
                $category + ['is_active' => true],
            );
        }
    }
}
