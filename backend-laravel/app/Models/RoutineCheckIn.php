<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class RoutineCheckIn extends Model
{
    protected $fillable = [
        'user_routine_id',
        'check_date',
        'morning_done',
        'night_done',
        'morning_completed_at',
        'night_completed_at',
    ];

    protected function casts(): array
    {
        return [
            'check_date' => 'date',
            'morning_done' => 'boolean',
            'night_done' => 'boolean',
            'morning_completed_at' => 'datetime',
            'night_completed_at' => 'datetime',
        ];
    }

    /**
     * @return BelongsTo<UserRoutine, $this>
     */
    public function routine(): BelongsTo
    {
        return $this->belongsTo(UserRoutine::class, 'user_routine_id');
    }
}
