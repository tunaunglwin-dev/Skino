<?php

namespace App\Models;

use Database\Factories\ContactFactory;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

#[Fillable([
    'user_id',
    'display_name',
    'contact_type',
    'source',
    'status',
    'gmail_email',
    'email',
    'phone',
    'avatar_url',
    'specialty',
    'company_name',
    'tags',
    'internal_note',
    'last_seen_at',
])]
class Contact extends Model
{
    /** @use HasFactory<ContactFactory> */
    use HasFactory;

    public const TYPE_USER = 'user';

    public const TYPE_SPECIALIST = 'specialist';

    public const TYPE_SELLER = 'seller';

    public const TYPE_VENDOR = 'vendor';

    public const TYPE_INTERNAL = 'internal';

    public const TYPE_LEAD = 'lead';

    public const SOURCE_GOOGLE = 'google';

    public const SOURCE_MANUAL = 'manual';

    public const SOURCE_SYSTEM = 'system';

    public const STATUS_ACTIVE = 'active';

    public const STATUS_ARCHIVED = 'archived';

    public const STATUS_BLOCKED = 'blocked';

    /**
     * @return array<int, string>
     */
    public static function types(): array
    {
        return [
            self::TYPE_USER,
            self::TYPE_SPECIALIST,
            self::TYPE_SELLER,
            self::TYPE_VENDOR,
            self::TYPE_INTERNAL,
            self::TYPE_LEAD,
        ];
    }

    /**
     * @return array<int, string>
     */
    public static function sources(): array
    {
        return [self::SOURCE_GOOGLE, self::SOURCE_MANUAL, self::SOURCE_SYSTEM];
    }

    /**
     * @return array<int, string>
     */
    public static function statuses(): array
    {
        return [self::STATUS_ACTIVE, self::STATUS_ARCHIVED, self::STATUS_BLOCKED];
    }

    /**
     * @return BelongsTo<User, Contact>
     */
    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    /**
     * @return HasMany<ContactNote>
     */
    public function notes(): HasMany
    {
        return $this->hasMany(ContactNote::class);
    }

    /**
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'tags' => 'array',
            'last_seen_at' => 'datetime',
        ];
    }
}
