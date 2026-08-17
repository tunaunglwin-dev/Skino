<?php

namespace App\Models;

use Database\Factories\CrmRecordFactory;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

#[Fillable([
    'contact_id',
    'specialist_contact_id',
    'owner_id',
    'title',
    'stage',
    'priority',
    'source',
    'appointment_status',
    'scheduled_at',
    'beauty_goal',
    'concern_summary',
    'tags',
])]
class CrmRecord extends Model
{
    /** @use HasFactory<CrmRecordFactory> */
    use HasFactory;

    public const STAGE_NEW = 'new';

    public const STAGE_CONTACTED = 'contacted';

    public const STAGE_APPOINTMENT = 'appointment_scheduled';

    public const STAGE_COMPLETED = 'completed';

    public const STAGE_CLOSED = 'closed';

    public const PRIORITY_LOW = 'low';

    public const PRIORITY_NORMAL = 'normal';

    public const PRIORITY_HIGH = 'high';

    public const PRIORITY_URGENT = 'urgent';

    public const APPOINTMENT_NOT_SCHEDULED = 'not_scheduled';

    public const APPOINTMENT_SCHEDULED = 'scheduled';

    public const APPOINTMENT_COMPLETED = 'completed';

    public const APPOINTMENT_CANCELLED = 'cancelled';

    public static function stages(): array
    {
        return [self::STAGE_NEW, self::STAGE_CONTACTED, self::STAGE_APPOINTMENT, self::STAGE_COMPLETED, self::STAGE_CLOSED];
    }

    public static function priorities(): array
    {
        return [self::PRIORITY_LOW, self::PRIORITY_NORMAL, self::PRIORITY_HIGH, self::PRIORITY_URGENT];
    }

    public static function appointmentStatuses(): array
    {
        return [
            self::APPOINTMENT_NOT_SCHEDULED,
            self::APPOINTMENT_SCHEDULED,
            self::APPOINTMENT_COMPLETED,
            self::APPOINTMENT_CANCELLED,
        ];
    }

    public function contact(): BelongsTo
    {
        return $this->belongsTo(Contact::class);
    }

    public function specialist(): BelongsTo
    {
        return $this->belongsTo(Contact::class, 'specialist_contact_id');
    }

    public function owner(): BelongsTo
    {
        return $this->belongsTo(User::class, 'owner_id');
    }

    public function notes(): HasMany
    {
        return $this->hasMany(CrmNote::class);
    }

    protected function casts(): array
    {
        return [
            'scheduled_at' => 'datetime',
            'tags' => 'array',
        ];
    }
}
