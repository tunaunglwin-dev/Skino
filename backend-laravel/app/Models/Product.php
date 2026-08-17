<?php

namespace App\Models;

use Database\Factories\ProductFactory;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\BelongsToMany;
use Illuminate\Database\Eloquent\SoftDeletes;

class Product extends Model
{
    /** @use HasFactory<ProductFactory> */
    use HasFactory, SoftDeletes;

    protected $fillable = [
        'product_category_id',
        'sku',
        'slug',
        'name',
        'brand',
        'description',
        'price',
        'currency',
        'image_url',
        'metadata',
        'is_active',
    ];

    protected function casts(): array
    {
        return [
            'price' => 'decimal:2',
            'metadata' => 'array',
            'is_active' => 'boolean',
        ];
    }

    /**
     * @return BelongsTo<ProductCategory, $this>
     */
    public function category(): BelongsTo
    {
        return $this->belongsTo(ProductCategory::class, 'product_category_id');
    }

    /**
     * @return BelongsToMany<SkinConcern, $this>
     */
    public function skinConcerns(): BelongsToMany
    {
        return $this->belongsToMany(SkinConcern::class)
            ->withPivot(['recommendation_weight', 'notes'])
            ->withTimestamps();
    }

    /**
     * @return BelongsToMany<SkinType, $this>
     */
    public function skinTypes(): BelongsToMany
    {
        return $this->belongsToMany(SkinType::class)
            ->withPivot(['recommendation_weight', 'notes'])
            ->withTimestamps();
    }
}
