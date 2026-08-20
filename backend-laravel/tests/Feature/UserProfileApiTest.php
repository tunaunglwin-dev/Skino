<?php

namespace Tests\Feature;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class UserProfileApiTest extends TestCase
{
    use RefreshDatabase;

    public function test_user_can_save_optional_research_profile_fields(): void
    {
        $user = User::factory()->create(['name' => 'Old Name']);
        Sanctum::actingAs($user);

        $this->putJson('/api/profile', [
            'name' => 'May Thu',
            'age_band' => '25_34',
            'skin_tone_scale' => 6,
            'skin_goals' => ['acne', 'pigmentation'],
        ])
            ->assertOk()
            ->assertJsonPath('data.name', 'May Thu')
            ->assertJsonPath('data.age_band', '25_34')
            ->assertJsonPath('data.skin_tone_scale', 6)
            ->assertJsonPath('data.skin_goals.1', 'pigmentation');

        $this->assertNotNull($user->refresh()->profile_completed_at);
    }

    public function test_profile_rejects_invalid_demographic_values(): void
    {
        Sanctum::actingAs(User::factory()->create());

        $this->putJson('/api/profile', [
            'name' => 'May Thu',
            'age_band' => 'exactly_27',
            'skin_tone_scale' => 20,
            'skin_goals' => ['diagnose_me'],
        ])
            ->assertUnprocessable()
            ->assertJsonValidationErrors(['age_band', 'skin_tone_scale', 'skin_goals.0']);
    }
}
