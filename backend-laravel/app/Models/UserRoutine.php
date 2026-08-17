<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class UserRoutine extends Model
{
    protected $fillable = [
        'user_id',
        'skin_analysis_id',
        'routine_payload',
        'is_active',
        'started_at',
    ];

    protected function casts(): array
    {
        return [
            'routine_payload' => 'array',
            'is_active' => 'boolean',
            'started_at' => 'datetime',
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
     * @return BelongsTo<SkinAnalysis, $this>
     */
    public function skinAnalysis(): BelongsTo
    {
        return $this->belongsTo(SkinAnalysis::class);
    }

    /**
     * @return HasMany<RoutineCheckIn, $this>
     */
    public function checkIns(): HasMany
    {
        return $this->hasMany(RoutineCheckIn::class);
    }
}
