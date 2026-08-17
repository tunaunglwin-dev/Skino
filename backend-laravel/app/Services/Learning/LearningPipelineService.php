<?php

namespace App\Services\Learning;

use App\Models\AiTrainingConsent;
use App\Models\ModelTrainingSample;
use App\Models\SkinAnalysis;
use App\Models\SkinAnalysisImage;
use App\Models\User;
use Illuminate\Http\UploadedFile;

class LearningPipelineService
{
    public function recordImage(
        User $user,
        SkinAnalysis $analysis,
        UploadedFile $image,
        string $path,
        bool $allowModelTraining,
    ): SkinAnalysisImage {
        $consent = $this->currentConsent($user);
        $hasConsent = $allowModelTraining || ($consent?->granted ?? false);

        if ($allowModelTraining) {
            $consent = $this->setConsent($user, true);
        }

        $imageRecord = SkinAnalysisImage::query()->create([
            'user_id' => $user->id,
            'skin_analysis_id' => $analysis->id,
            'storage_disk' => 'local',
            'image_path' => $path,
            'original_filename' => $image->getClientOriginalName(),
            'mime_type' => $image->getMimeType(),
            'size_bytes' => $image->getSize(),
            'privacy_status' => $hasConsent
                ? SkinAnalysisImage::PRIVACY_TRAINING_ALLOWED
                : SkinAnalysisImage::PRIVACY_PRIVATE,
            'retention_policy' => 'user_history',
        ]);

        if ($hasConsent && $consent instanceof AiTrainingConsent) {
            $this->queueTrainingSample($user, $analysis, $imageRecord, $consent);
        }

        return $imageRecord;
    }

    public function setConsent(User $user, bool $granted): AiTrainingConsent
    {
        return AiTrainingConsent::query()->updateOrCreate(
            [
                'user_id' => $user->id,
                'consent_type' => AiTrainingConsent::TYPE_MODEL_TRAINING,
            ],
            [
                'policy_version' => AiTrainingConsent::CURRENT_POLICY_VERSION,
                'granted' => $granted,
                'granted_at' => $granted ? now() : null,
                'revoked_at' => $granted ? null : now(),
            ],
        );
    }

    public function currentConsent(User $user): ?AiTrainingConsent
    {
        return AiTrainingConsent::query()
            ->where('user_id', $user->id)
            ->where('consent_type', AiTrainingConsent::TYPE_MODEL_TRAINING)
            ->first();
    }

    private function queueTrainingSample(
        User $user,
        SkinAnalysis $analysis,
        SkinAnalysisImage $imageRecord,
        AiTrainingConsent $consent,
    ): ModelTrainingSample {
        return ModelTrainingSample::query()->create([
            'user_id' => $user->id,
            'skin_analysis_id' => $analysis->id,
            'skin_analysis_image_id' => $imageRecord->id,
            'ai_training_consent_id' => $consent->id,
            'label_source' => 'ai',
            'review_status' => ModelTrainingSample::REVIEW_PENDING,
            'training_status' => ModelTrainingSample::TRAINING_QUEUED,
            'snapshot_payload' => [
                'skin_type' => $analysis->skin_type_slug,
                'skin_type_confidence' => $analysis->skin_type_confidence,
                'concerns' => $analysis->concerns ?? [],
                'acne_severity' => $analysis->acne_severity,
                'skin_health_score' => $analysis->skin_health_score,
            ],
            'anonymized_metadata' => [
                'analysis_id' => $analysis->id,
                'captured_at' => $analysis->created_at?->toISOString(),
                'policy_version' => $consent->policy_version,
            ],
        ]);
    }
}
