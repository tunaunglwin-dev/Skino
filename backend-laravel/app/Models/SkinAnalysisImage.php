<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

#[Fillable([
    'user_id',
    'skin_analysis_id',
    'storage_disk',
    'image_path',
    'original_filename',
    'mime_type',
    'size_bytes',
    'privacy_status',
    'retention_policy',
    'deleted_at',
])]
class SkinAnalysisImage extends Model
{
    public const PRIVACY_PRIVATE = 'private';

    public const PRIVACY_TRAINING_ALLOWED = 'training_allowed';

    /**
     * @return BelongsTo<User, SkinAnalysisImage>
     */
    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    /**
     * @return BelongsTo<SkinAnalysis, SkinAnalysisImage>
     */
    public function analysis(): BelongsTo
    {
        return $this->belongsTo(SkinAnalysis::class, 'skin_analysis_id');
    }

    protected function casts(): array
    {
        return [
            'size_bytes' => 'integer',
            'deleted_at' => 'datetime',
        ];
    }
}
