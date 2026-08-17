<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

#[Fillable(['crm_record_id', 'author_id', 'note_type', 'body'])]
class CrmNote extends Model
{
    public function record(): BelongsTo
    {
        return $this->belongsTo(CrmRecord::class, 'crm_record_id');
    }

    public function author(): BelongsTo
    {
        return $this->belongsTo(User::class, 'author_id');
    }
}
