<?php

namespace Database\Factories;

use App\Models\SkinConcern;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<SkinConcern>
 */
class SkinConcernFactory extends Factory
{
    /**
     * Define the model's default state.
     *
     * @return array<string, mixed>
     */
    public function definition(): array
    {
        $name = fake()->unique()->randomElement(['Acne', 'Dark Spots', 'Redness', 'Dryness', 'Oiliness']);

        return [
            'slug' => str($name)->slug()->toString(),
            'name' => $name,
            'description' => fake()->sentence(),
            'sort_order' => fake()->numberBetween(1, 50),
            'is_active' => true,
        ];
    }
}
