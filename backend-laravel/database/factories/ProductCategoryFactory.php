<?php

namespace Database\Factories;

use App\Models\ProductCategory;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<ProductCategory>
 */
class ProductCategoryFactory extends Factory
{
    /**
     * Define the model's default state.
     *
     * @return array<string, mixed>
     */
    public function definition(): array
    {
        $name = fake()->unique()->randomElement(['Cleanser', 'Moisturizer', 'Serum', 'Sunscreen', 'Toner']);

        return [
            'slug' => str($name)->slug()->toString(),
            'name' => $name,
            'description' => fake()->sentence(),
            'sort_order' => fake()->numberBetween(1, 50),
            'is_active' => true,
        ];
    }
}
