<?php

namespace Database\Factories;

use App\Models\Product;
use App\Models\ProductCategory;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<Product>
 */
class ProductFactory extends Factory
{
    /**
     * Define the model's default state.
     *
     * @return array<string, mixed>
     */
    public function definition(): array
    {
        $name = fake()->unique()->words(3, true);

        return [
            'product_category_id' => ProductCategory::factory(),
            'sku' => fake()->unique()->bothify('SKU-####-????'),
            'slug' => str($name)->slug()->toString(),
            'name' => str($name)->title()->toString(),
            'brand' => fake()->company(),
            'description' => fake()->paragraph(),
            'price' => fake()->randomFloat(2, 5, 100),
            'currency' => 'USD',
            'image_url' => fake()->optional()->imageUrl(640, 640, 'skincare'),
            'metadata' => [
                'size' => fake()->randomElement(['30ml', '50ml', '100ml', '150ml']),
            ],
            'is_active' => true,
        ];
    }
}
