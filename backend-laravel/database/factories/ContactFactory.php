<?php

namespace Database\Factories;

use App\Models\Contact;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<Contact>
 */
class ContactFactory extends Factory
{
    public function definition(): array
    {
        return [
            'display_name' => fake()->name(),
            'contact_type' => Contact::TYPE_USER,
            'source' => Contact::SOURCE_MANUAL,
            'status' => Contact::STATUS_ACTIVE,
            'email' => fake()->unique()->safeEmail(),
            'phone' => fake()->phoneNumber(),
            'tags' => ['mobile-user'],
        ];
    }

    public function specialist(): static
    {
        return $this->state(fn (array $attributes) => [
            'contact_type' => Contact::TYPE_SPECIALIST,
            'specialty' => 'Dermatology',
            'tags' => ['specialist'],
        ]);
    }
}
