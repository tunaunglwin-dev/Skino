<?php

namespace Database\Seeders;

use App\Models\Product;
use App\Models\ProductCategory;
use App\Models\SkinConcern;
use App\Models\SkinType;
use Illuminate\Database\Seeder;

class ProductSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        $products = [
            [
                'category' => 'cleanser',
                'sku' => 'SKIN-CLN-001',
                'slug' => 'gentle-gel-cleanser',
                'name' => 'Gentle Gel Cleanser',
                'brand' => 'DermaCare',
                'description' => 'A gentle daily cleanser for oily and combination skin.',
                'price' => 14.99,
                'skin_types' => ['oily' => 75, 'combination' => 70],
                'concerns' => ['acne' => 70, 'oiliness' => 80],
            ],
            [
                'category' => 'moisturizer',
                'sku' => 'SKIN-MST-001',
                'slug' => 'barrier-repair-moisturizer',
                'name' => 'Barrier Repair Moisturizer',
                'brand' => 'SkinBalance',
                'description' => 'A simple moisturizer for dry and sensitive skin support.',
                'price' => 19.99,
                'skin_types' => ['dry' => 85, 'sensitive' => 75, 'normal' => 60],
                'concerns' => ['dryness' => 85, 'redness' => 55],
            ],
            [
                'category' => 'serum',
                'sku' => 'SKIN-SRM-001',
                'slug' => 'brightening-niacinamide-serum',
                'name' => 'Brightening Niacinamide Serum',
                'brand' => 'GlowLab',
                'description' => 'A targeted serum for uneven tone and visible dark spots.',
                'price' => 24.99,
                'skin_types' => ['oily' => 70, 'combination' => 70, 'normal' => 65],
                'concerns' => ['dark_spots' => 85, 'texture' => 55, 'oiliness' => 55],
            ],
            [
                'category' => 'sunscreen',
                'sku' => 'SKIN-SPF-001',
                'slug' => 'daily-lightweight-sunscreen',
                'name' => 'Daily Lightweight Sunscreen',
                'brand' => 'SunKind',
                'description' => 'A lightweight daily sunscreen for morning routines.',
                'price' => 17.99,
                'skin_types' => ['oily' => 65, 'combination' => 65, 'normal' => 65, 'sensitive' => 55],
                'concerns' => ['dark_spots' => 75, 'redness' => 45],
            ],
        ];

        foreach ($products as $productData) {
            $category = ProductCategory::query()->where('slug', $productData['category'])->firstOrFail();

            $product = Product::query()->updateOrCreate(
                ['slug' => $productData['slug']],
                [
                    'product_category_id' => $category->id,
                    'sku' => $productData['sku'],
                    'name' => $productData['name'],
                    'brand' => $productData['brand'],
                    'description' => $productData['description'],
                    'price' => $productData['price'],
                    'currency' => 'USD',
                    'is_active' => true,
                ],
            );

            $product->skinTypes()->sync($this->weightedIds(SkinType::class, $productData['skin_types']));
            $product->skinConcerns()->sync($this->weightedIds(SkinConcern::class, $productData['concerns']));
        }
    }

    /**
     * @param  class-string<SkinType|SkinConcern>  $model
     * @param  array<string, int>  $weights
     * @return array<int, array<string, int>>
     */
    private function weightedIds(string $model, array $weights): array
    {
        return collect($weights)
            ->mapWithKeys(function (int $weight, string $slug) use ($model): array {
                $record = $model::query()->where('slug', $slug)->firstOrFail();

                return [
                    $record->id => ['recommendation_weight' => $weight],
                ];
            })
            ->all();
    }
}
