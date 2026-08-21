<?php

namespace Tests\Feature;

use App\Models\AiTrainingConsent;
use App\Models\ModelTrainingSample;
use App\Models\SkinAnalysis;
use App\Models\SkinAnalysisImage;
use App\Models\User;
use App\Models\UserRoutine;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Storage;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class SkinAnalysisApiTest extends TestCase
{
    use RefreshDatabase;

    public function test_analysis_endpoints_require_authentication(): void
    {
        $this->getJson('/api/skin-analyses')->assertUnauthorized();

        $this->postJson('/api/skin-analyses')->assertUnauthorized();
    }

    public function test_authenticated_user_can_create_analysis_and_receive_recommendations(): void
    {
        Storage::fake('local');
        Http::fake([
            '127.0.0.1:5000/analyze' => Http::response([
                'skin_type' => 'oily',
                'skin_type_confidence' => 0.82,
                'concerns' => [
                    ['name' => 'acne', 'confidence' => 0.76, 'severity' => 'moderate'],
                    ['name' => 'dark_spots', 'confidence' => 0.61, 'severity' => 'mild'],
                ],
                'skin_zones' => [
                    [
                        'key' => 'chin',
                        'label' => 'Chin',
                        'concerns' => [
                            ['name' => 'acne', 'confidence' => 0.72, 'severity' => 'moderate'],
                        ],
                        'score' => 64,
                        'oiliness' => 0.31,
                        'dark_spots' => 0.18,
                        'redness' => 0.72,
                        'texture' => 0.44,
                        'dryness' => 0.22,
                    ],
                ],
                'acne_severity' => 'moderate',
                'skin_health_score' => 68,
                'treatment_package' => [
                    'key' => 'acne',
                    'name' => 'Acne Control Plan',
                    'steps' => ['gentle cleanser', 'spot treatment', 'non-comedogenic moisturizer', 'sunscreen'],
                    'follow_up_days' => 14,
                    'reason' => 'Matched to acne from the latest scan.',
                ],
            ]),
        ]);

        $this->seed();
        Sanctum::actingAs(User::factory()->create());

        $faceLandmarks = json_encode(array_fill(0, 468, [
            'x' => 0.5,
            'y' => 0.5,
            'z' => 0.0,
        ]), JSON_THROW_ON_ERROR);

        $response = $this->postJson('/api/skin-analyses', [
            'image' => $this->fakePngUpload(),
            'frames' => [$this->fakePngUpload(), $this->fakePngUpload()],
            'capture_mode' => 'multi_frame_median',
            'frame_count' => 3,
            'face_landmarks' => $faceLandmarks,
        ]);

        $response
            ->assertCreated()
            ->assertJsonPath('data.skin_type', 'oily')
            ->assertJsonPath('data.concerns.0.name', 'acne')
            ->assertJsonPath('data.skin_zones.0.key', 'chin')
            ->assertJsonPath('data.skin_zones.0.concerns.0.name', 'acne')
            ->assertJsonPath('data.acne_severity', 'moderate')
            ->assertJsonPath('data.treatment_package.name', 'Acne Control Plan')
            ->assertJsonPath('data.recommended_products.0.slug', 'gentle-gel-cleanser');

        $analysis = SkinAnalysis::query()->firstOrFail();

        Storage::disk('local')->assertExists($analysis->image_path);
        $this->assertSame('oily', $analysis->skin_type_slug);
        $this->assertSame('moderate', $analysis->acne_severity);
        $this->assertSame(68, $analysis->skin_health_score);
        $this->assertDatabaseHas('skin_analysis_images', [
            'skin_analysis_id' => $analysis->id,
            'privacy_status' => SkinAnalysisImage::PRIVACY_PRIVATE,
        ]);
        $this->assertDatabaseCount('model_training_samples', 0);

        Http::assertSent(fn ($request) => str_contains($request->body(), 'face_landmarks')
            && str_contains($request->body(), $faceLandmarks)
            && substr_count($request->body(), 'name="frames"') === 2);
        Http::assertSentCount(1);
    }

    public function test_authenticated_user_can_opt_scan_into_model_learning_queue(): void
    {
        Storage::fake('local');
        Http::fake([
            '127.0.0.1:5000/analyze' => Http::response([
                'skin_type' => 'oily',
                'skin_type_confidence' => 0.82,
                'concerns' => [
                    ['name' => 'acne', 'confidence' => 0.76, 'severity' => 'moderate'],
                ],
                'acne_severity' => 'moderate',
                'skin_health_score' => 68,
            ]),
        ]);

        $this->seed();
        Sanctum::actingAs(User::factory()->create([
            'age_band' => '25_34',
            'skin_tone_scale' => 6,
            'skin_goals' => ['acne'],
        ]));

        $response = $this->postJson('/api/skin-analyses', [
            'image' => $this->fakePngUpload(),
            'allow_model_training' => true,
            'capture_mode' => 'multi_frame_best',
            'frame_count' => 3,
            'client_quality_score' => 84,
            'device_category' => 'mobile',
        ]);

        $response
            ->assertCreated()
            ->assertJsonPath('data.privacy.image_privacy_status', SkinAnalysisImage::PRIVACY_TRAINING_ALLOWED)
            ->assertJsonPath('data.privacy.training_queued', true);

        $this->assertDatabaseHas('ai_training_consents', [
            'consent_type' => 'model_training',
            'granted' => true,
        ]);
        $this->assertDatabaseHas('model_training_samples', [
            'label_source' => 'ai',
            'review_status' => 'pending',
            'training_status' => 'queued',
        ]);

        $metadata = ModelTrainingSample::query()->firstOrFail()->anonymized_metadata;
        $this->assertSame('25_34', $metadata['age_band']);
        $this->assertSame(6, $metadata['skin_tone_scale']);
        $this->assertSame('multi_frame_best', $metadata['capture_context']['mode']);
        $this->assertSame(3, $metadata['capture_context']['frame_count']);
    }

    public function test_user_can_view_and_revoke_model_training_consent(): void
    {
        $user = User::factory()->create();
        Sanctum::actingAs($user);

        $this->getJson('/api/privacy/model-training-consent')
            ->assertOk()
            ->assertJsonPath('data.granted', false);

        $this->putJson('/api/privacy/model-training-consent', [
            'granted' => true,
        ])
            ->assertOk()
            ->assertJsonPath('data.granted', true);

        $this->putJson('/api/privacy/model-training-consent', [
            'granted' => false,
        ])
            ->assertOk()
            ->assertJsonPath('data.granted', false);

        $this->assertDatabaseHas('ai_training_consents', [
            'user_id' => $user->id,
            'granted' => false,
        ]);
    }

    public function test_user_can_accept_versioned_required_consents(): void
    {
        $user = User::factory()->create();
        Sanctum::actingAs($user);

        $this->getJson('/api/privacy/required-consents')
            ->assertOk()
            ->assertJsonPath('data.complete', false)
            ->assertJsonPath('data.terms.granted', false)
            ->assertJsonPath('data.scan_processing.granted', false);

        $this->putJson('/api/privacy/required-consents', [
            'terms' => true,
            'scan_processing' => true,
        ])
            ->assertOk()
            ->assertJsonPath('data.complete', true)
            ->assertJsonPath('data.policy_version', AiTrainingConsent::REQUIRED_POLICY_VERSION);

        $this->assertDatabaseHas('ai_training_consents', [
            'user_id' => $user->id,
            'consent_type' => AiTrainingConsent::TYPE_TERMS,
            'policy_version' => AiTrainingConsent::REQUIRED_POLICY_VERSION,
            'granted' => true,
        ]);
        $this->assertDatabaseHas('ai_training_consents', [
            'user_id' => $user->id,
            'consent_type' => AiTrainingConsent::TYPE_SCAN_PROCESSING,
            'policy_version' => AiTrainingConsent::REQUIRED_POLICY_VERSION,
            'granted' => true,
        ]);
    }

    public function test_guest_can_analyze_without_saving_history(): void
    {
        Storage::fake('local');
        Http::fake([
            '127.0.0.1:5000/analyze' => Http::response([
                'skin_type' => 'normal',
                'skin_type_confidence' => 0.74,
                'concerns' => [],
                'skin_zones' => [
                    [
                        'key' => 'forehead',
                        'label' => 'Forehead',
                        'concerns' => [],
                        'score' => 88,
                        'oiliness' => 0.21,
                        'dark_spots' => 0.12,
                        'redness' => 0.09,
                        'texture' => 0.24,
                        'dryness' => 0.18,
                    ],
                ],
                'acne_severity' => 'none',
                'skin_health_score' => 90,
                'treatment_package' => [
                    'key' => 'normal',
                    'name' => 'Daily Glow Maintenance',
                    'steps' => ['gentle cleanser', 'light moisturizer', 'broad-spectrum sunscreen'],
                    'follow_up_days' => 30,
                    'reason' => 'Matched to normal skin maintenance.',
                ],
            ]),
        ]);

        $response = $this->postJson('/api/guest/skin-analysis', [
            'image' => $this->fakePngUpload(),
        ]);

        $response
            ->assertOk()
            ->assertJsonPath('data.guest_mode', true)
            ->assertJsonPath('data.skin_type', 'normal')
            ->assertJsonPath('data.skin_zones.0.key', 'forehead')
            ->assertJsonPath('data.acne_severity', 'none')
            ->assertJsonPath('data.beauty_routine.name', 'Daily Glow Maintenance');

        $this->assertDatabaseCount('skin_analyses', 0);
    }

    public function test_analysis_upload_requires_valid_image(): void
    {
        Sanctum::actingAs(User::factory()->create());

        $this->postJson('/api/skin-analyses', [
            'image' => UploadedFile::fake()->create('notes.txt', 1, 'text/plain'),
        ])
            ->assertUnprocessable()
            ->assertJsonValidationErrors(['image']);
    }

    public function test_authenticated_user_can_read_own_analysis_history(): void
    {
        $this->seed();

        $user = User::factory()->create();
        $otherUser = User::factory()->create();

        SkinAnalysis::factory()->create(['user_id' => $user->id]);
        SkinAnalysis::factory()->create(['user_id' => $otherUser->id]);

        Sanctum::actingAs($user);

        $this->getJson('/api/skin-analyses')
            ->assertOk()
            ->assertJsonCount(1, 'data');
    }

    public function test_user_cannot_read_another_users_analysis(): void
    {
        $analysis = SkinAnalysis::factory()->create();

        Sanctum::actingAs(User::factory()->create());

        $this->getJson('/api/skin-analyses/'.$analysis->id)
            ->assertNotFound();
    }

    public function test_user_cannot_delete_scan_used_by_active_routine(): void
    {
        $user = User::factory()->create();
        $analysis = SkinAnalysis::factory()->create(['user_id' => $user->id]);

        UserRoutine::query()->create([
            'user_id' => $user->id,
            'skin_analysis_id' => $analysis->id,
            'routine_payload' => [
                'name' => 'Acne Control Plan',
                'steps' => ['cleanser', 'spot treatment', 'sunscreen'],
                'follow_up_days' => 14,
            ],
            'is_active' => true,
            'started_at' => now(),
        ]);

        Sanctum::actingAs($user);

        $this->deleteJson('/api/skin-analyses/'.$analysis->id)
            ->assertStatus(409)
            ->assertJsonPath(
                'message',
                'This scan is used by your active routine. Stop or replace the routine before deleting this scan.',
            );

        $this->assertDatabaseHas('skin_analyses', ['id' => $analysis->id]);
    }

    public function test_user_can_delete_scan_when_related_routine_is_inactive(): void
    {
        $user = User::factory()->create();
        $analysis = SkinAnalysis::factory()->create(['user_id' => $user->id]);

        UserRoutine::query()->create([
            'user_id' => $user->id,
            'skin_analysis_id' => $analysis->id,
            'routine_payload' => [
                'name' => 'Acne Control Plan',
                'steps' => ['cleanser', 'spot treatment', 'sunscreen'],
                'follow_up_days' => 14,
            ],
            'is_active' => false,
            'started_at' => now()->subDays(7),
        ]);

        Sanctum::actingAs($user);

        $this->deleteJson('/api/skin-analyses/'.$analysis->id)
            ->assertNoContent();

        $this->assertDatabaseMissing('skin_analyses', ['id' => $analysis->id]);
    }

    public function test_ai_service_failure_returns_bad_gateway_without_storing_analysis(): void
    {
        Http::fake([
            '127.0.0.1:5000/analyze' => Http::response(['message' => 'down'], 500),
        ]);

        Sanctum::actingAs(User::factory()->create());

        $this->postJson('/api/skin-analyses', [
            'image' => $this->fakePngUpload(),
        ])
            ->assertStatus(502)
            ->assertJsonPath('message', 'Skin analysis service is unavailable.');

        $this->assertDatabaseCount('skin_analyses', 0);
    }

    private function fakePngUpload(): UploadedFile
    {
        $path = tempnam(sys_get_temp_dir(), 'skin-analysis-').'.png';

        file_put_contents(
            $path,
            base64_decode('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+/p9sAAAAASUVORK5CYII='),
        );

        return new UploadedFile($path, 'face.png', 'image/png', null, true);
    }
}
