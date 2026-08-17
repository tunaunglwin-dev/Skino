<?php

namespace Tests\Feature;

use App\Models\ModelTrainingSample;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Storage;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class AdminTrainingSamplesApiTest extends TestCase
{
    use RefreshDatabase;

    public function test_admin_can_list_and_approve_training_sample(): void
    {
        $sample = $this->createTrainingSample();
        Sanctum::actingAs(User::factory()->admin()->create());

        $this->getJson('/api/admin/training-samples?review_status=pending')
            ->assertOk()
            ->assertJsonCount(1, 'data')
            ->assertJsonPath('data.0.id', $sample->id)
            ->assertJsonPath('data.0.image.privacy_status', 'training_allowed');

        $this->postJson("/api/admin/training-samples/{$sample->id}/review", [
            'action' => 'approve',
            'review_note' => 'Good quality frontal image.',
        ])
            ->assertOk()
            ->assertJsonPath('data.review_status', ModelTrainingSample::REVIEW_APPROVED)
            ->assertJsonPath('data.training_status', ModelTrainingSample::TRAINING_APPROVED);
    }

    public function test_admin_can_correct_training_labels(): void
    {
        $sample = $this->createTrainingSample();
        Sanctum::actingAs(User::factory()->admin()->create());

        $this->postJson("/api/admin/training-samples/{$sample->id}/review", [
            'action' => 'correct',
            'corrected_labels' => [
                'skin_type' => 'combination',
                'acne_severity' => 'mild',
                'concerns' => ['acne', 'dark_spots'],
            ],
            'review_note' => 'Severity looked milder than model prediction.',
        ])
            ->assertOk()
            ->assertJsonPath('data.corrected_labels.skin_type', 'combination')
            ->assertJsonPath('data.review_status', ModelTrainingSample::REVIEW_APPROVED);
    }

    public function test_admin_can_reject_or_mark_needs_specialist(): void
    {
        $sample = $this->createTrainingSample();
        Sanctum::actingAs(User::factory()->admin()->create());

        $this->postJson("/api/admin/training-samples/{$sample->id}/review", [
            'action' => 'needs_specialist',
            'review_note' => 'Image has unclear lighting.',
        ])
            ->assertOk()
            ->assertJsonPath('data.review_status', ModelTrainingSample::REVIEW_NEEDS_SPECIALIST)
            ->assertJsonPath('data.training_status', ModelTrainingSample::TRAINING_QUEUED);

        $this->postJson("/api/admin/training-samples/{$sample->id}/review", [
            'action' => 'reject',
            'review_note' => 'Reject after specialist review.',
        ])
            ->assertOk()
            ->assertJsonPath('data.review_status', ModelTrainingSample::REVIEW_REJECTED)
            ->assertJsonPath('data.training_status', ModelTrainingSample::TRAINING_EXCLUDED);
    }

    public function test_non_admin_cannot_review_training_samples(): void
    {
        $sample = $this->createTrainingSample();
        Sanctum::actingAs(User::factory()->create());

        $this->getJson('/api/admin/training-samples')->assertForbidden();
        $this->postJson("/api/admin/training-samples/{$sample->id}/review", [
            'action' => 'approve',
        ])->assertForbidden();
    }

    private function createTrainingSample(): ModelTrainingSample
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
        Sanctum::actingAs(User::factory()->create());

        $this->postJson('/api/skin-analyses', [
            'image' => $this->fakePngUpload(),
            'allow_model_training' => true,
        ])->assertCreated();

        return ModelTrainingSample::query()->firstOrFail();
    }

    private function fakePngUpload(): UploadedFile
    {
        $path = tempnam(sys_get_temp_dir(), 'skin-training-').'.png';

        file_put_contents(
            $path,
            base64_decode('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+/p9sAAAAASUVORK5CYII='),
        );

        return new UploadedFile($path, 'face.png', 'image/png', null, true);
    }
}
