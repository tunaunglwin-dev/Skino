<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

#[Fillable([
    'user_id',
    'skin_analysis_id',
    'skin_analysis_image_id',
    'ai_training_consent_id',
    'label_source',
    'review_status',
    'training_status',
    'snapshot_payload',
    'anonymized_metadata',
    'reviewed_by_id',
    'corrected_labels',
    'review_note',
    'reviewed_at',
    'exported_at',
])]
class ModelTrainingSample extends Model
{
    public const REVIEW_PENDING = 'pending';

    public const REVIEW_APPROVED = 'approved';

    public const REVIEW_REJECTED = 'rejected';

    public const REVIEW_NEEDS_SPECIALIST = 'needs_specialist';

    public const TRAINING_QUEUED = 'queued';

    public const TRAINING_APPROVED = 'approved';

    public const TRAINING_EXCLUDED = 'excluded';

    /**
     * @return BelongsTo<SkinAnalysis, ModelTrainingSample>
     */
    public function analysis(): BelongsTo
    {
        return $this->belongsTo(SkinAnalysis::class, 'skin_analysis_id');
    }

    /**
     * @return BelongsTo<SkinAnalysisImage, ModelTrainingSample>
     */
    public function image(): BelongsTo
    {
        return $this->belongsTo(SkinAnalysisImage::class, 'skin_analysis_image_id');
    }

    /**
     * @return BelongsTo<AiTrainingConsent, ModelTrainingSample>
     */
    public function consent(): BelongsTo
    {
        return $this->belongsTo(AiTrainingConsent::class, 'ai_training_consent_id');
    }

    /**
     * @return BelongsTo<User, ModelTrainingSample>
     */
    public function reviewer(): BelongsTo
    {
        return $this->belongsTo(User::class, 'reviewed_by_id');
    }

    protected function casts(): array
    {
        return [
            'snapshot_payload' => 'array',
            'anonymized_metadata' => 'array',
            'corrected_labels' => 'array',
            'reviewed_at' => 'datetime',
            'exported_at' => 'datetime',
        ];
    }
}
