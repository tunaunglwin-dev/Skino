<?php

namespace App\Models;

use Database\Factories\SkinAnalysisFactory;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\Relations\HasOne;

class SkinAnalysis extends Model
{
    /** @use HasFactory<SkinAnalysisFactory> */
    use HasFactory;

    protected $fillable = [
        'user_id',
        'image_path',
        'skin_type_slug',
        'skin_type_confidence',
        'concerns',
        'acne_severity',
        'skin_health_score',
        'ai_provider',
        'raw_result',
    ];

    protected function casts(): array
    {
        return [
            'skin_type_confidence' => 'decimal:4',
            'concerns' => 'array',
            'acne_severity' => 'string',
            'raw_result' => 'array',
            'skin_health_score' => 'integer',
        ];
    }

    /**
     * @return BelongsTo<User, $this>
     */
    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    /**
     * @return HasOne<SkinAnalysisImage, $this>
     */
    public function imageRecord(): HasOne
    {
        return $this->hasOne(SkinAnalysisImage::class);
    }

    /**
     * @return HasMany<ModelTrainingSample, $this>
     */
    public function trainingSamples(): HasMany
    {
        return $this->hasMany(ModelTrainingSample::class);
    }
}
