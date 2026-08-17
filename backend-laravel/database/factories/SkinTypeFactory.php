<?php

namespace Database\Factories;

use App\Models\SkinType;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<SkinType>
 */
class SkinTypeFactory extends Factory
{
    /**
     * Define the model's default state.
     *
     * @return array<string, mixed>
     */
    public function definition(): array
    {
        $name = fake()->unique()->randomElement(['Oily', 'Dry', 'Combination', 'Sensitive', 'Normal']);

        return [
            'slug' => str($name)->slug()->toString(),
            'name' => $name,
            'description' => fake()->sentence(),
            'sort_order' => fake()->numberBetween(1, 50),
            'is_active' => true,
        ];
    }
}
