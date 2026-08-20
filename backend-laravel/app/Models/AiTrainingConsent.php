<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

#[Fillable(['user_id', 'consent_type', 'policy_version', 'granted', 'granted_at', 'revoked_at'])]
class AiTrainingConsent extends Model
{
    public const TYPE_MODEL_TRAINING = 'model_training';

    public const TYPE_TERMS = 'terms_and_privacy';

    public const TYPE_SCAN_PROCESSING = 'scan_processing';

    public const CURRENT_POLICY_VERSION = '2026-07-24';

    public const REQUIRED_POLICY_VERSION = '2026-08-20';

    /**
     * @return BelongsTo<User, AiTrainingConsent>
     */
    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    protected function casts(): array
    {
        return [
            'granted' => 'boolean',
            'granted_at' => 'datetime',
            'revoked_at' => 'datetime',
        ];
    }
}
