<?php

namespace Tests\Feature;

use App\Models\SkinAnalysis;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class UserRoutineApiTest extends TestCase
{
    use RefreshDatabase;

    public function test_user_can_start_active_routine_from_own_scan_and_update_today(): void
    {
        $user = User::factory()->create();
        $analysis = SkinAnalysis::factory()->create([
            'user_id' => $user->id,
            'raw_result' => [
                'skin_type' => 'oily',
                'skin_type_confidence' => 0.82,
                'concerns' => [],
                'acne_severity' => 'none',
                'skin_health_score' => 88,
                'treatment_package' => [
                    'key' => 'oily',
                    'name' => 'Oil Balance Care',
                    'steps' => ['gel cleanser', 'light moisturizer', 'sunscreen'],
                    'follow_up_days' => 14,
                    'reason' => 'Matched to oily skin.',
                ],
            ],
        ]);

        Sanctum::actingAs($user);

        $this->getJson('/api/routine')
            ->assertOk()
            ->assertJsonPath('data', null);

        $this->postJson('/api/routine/start', [
            'skin_analysis_id' => $analysis->id,
        ])
            ->assertCreated()
            ->assertJsonPath('data.skin_analysis_id', $analysis->id)
            ->assertJsonPath('data.routine.name', 'Oil Balance Care')
            ->assertJsonPath('data.today.morning_done', false)
            ->assertJsonPath('data.today.night_done', false);

        $this->putJson('/api/routine/today', [
            'morning_done' => true,
            'morning_steps' => ['cleanser', 'serum', 'moisturizer', 'sunscreen'],
            'night_done' => false,
        ])
            ->assertOk()
            ->assertJsonPath('data.today.morning_done', true)
            ->assertJsonPath('data.today.morning_steps.3', 'sunscreen')
            ->assertJsonPath('data.today.night_done', false);

        $this->putJson('/api/routine/today', [
            'night_done' => true,
            'night_steps' => ['cleanser', 'serum', 'moisturizer'],
        ])
            ->assertOk()
            ->assertJsonPath('data.today.morning_done', true)
            ->assertJsonPath('data.today.night_done', true)
            ->assertJsonPath('data.today.night_steps.1', 'serum');

        $this->putJson('/api/routine/today', [
            'morning_done' => false,
            'morning_steps' => ['cleanser'],
            'night_done' => false,
            'night_steps' => [],
        ])
            ->assertOk()
            ->assertJsonPath('data.today.morning_done', true)
            ->assertJsonPath('data.today.morning_steps.3', 'sunscreen')
            ->assertJsonPath('data.today.night_done', true)
            ->assertJsonPath('data.today.night_steps.2', 'moisturizer');

        $this->assertDatabaseHas('routine_check_ins', [
            'morning_done' => true,
            'night_done' => true,
        ]);
        $this->assertDatabaseCount('routine_check_ins', 1);
    }

    public function test_user_cannot_start_routine_from_another_users_scan(): void
    {
        Sanctum::actingAs(User::factory()->create());
        $analysis = SkinAnalysis::factory()->create();

        $this->postJson('/api/routine/start', [
            'skin_analysis_id' => $analysis->id,
        ])->assertNotFound();
    }

    public function test_user_cannot_start_routine_from_bad_quality_scan(): void
    {
        $user = User::factory()->create();
        $analysis = SkinAnalysis::factory()->create([
            'user_id' => $user->id,
            'raw_result' => [
                'treatment_package' => [
                    'name' => 'Acne Control Plan',
                    'steps' => ['cleanser', 'spot treatment', 'sunscreen'],
                    'follow_up_days' => 14,
                ],
                'scan_quality' => [
                    'needs_retake' => true,
                ],
            ],
        ]);

        Sanctum::actingAs($user);

        $this->postJson('/api/routine/start', [
            'skin_analysis_id' => $analysis->id,
        ])
            ->assertUnprocessable()
            ->assertJsonPath(
                'errors.skin_analysis_id.0',
                'This scan quality is too low to start a routine. Please retake with better lighting and framing.',
            );
    }

    public function test_user_can_stop_active_routine(): void
    {
        $user = User::factory()->create();
        $analysis = SkinAnalysis::factory()->create([
            'user_id' => $user->id,
            'raw_result' => [
                'treatment_package' => [
                    'name' => 'Acne Control Plan',
                    'steps' => ['cleanser', 'spot treatment', 'sunscreen'],
                    'follow_up_days' => 14,
                ],
            ],
        ]);

        Sanctum::actingAs($user);

        $this->postJson('/api/routine/start', [
            'skin_analysis_id' => $analysis->id,
        ])->assertCreated();

        $this->deleteJson('/api/routine')->assertNoContent();

        $this->assertDatabaseHas('user_routines', [
            'user_id' => $user->id,
            'skin_analysis_id' => $analysis->id,
            'is_active' => false,
        ]);

        $this->getJson('/api/routine')
            ->assertOk()
            ->assertJsonPath('data', null);
    }
}
