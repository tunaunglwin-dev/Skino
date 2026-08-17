<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Model;

#[Fillable(['name', 'version', 'status', 'metrics', 'dataset_snapshot', 'trained_at', 'deployed_at'])]
class ModelVersion extends Model
{
    protected function casts(): array
    {
        return [
            'metrics' => 'array',
            'dataset_snapshot' => 'array',
            'trained_at' => 'datetime',
            'deployed_at' => 'datetime',
        ];
    }
}
