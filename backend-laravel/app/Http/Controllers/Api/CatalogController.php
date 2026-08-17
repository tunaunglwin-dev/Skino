<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\Catalog\ProductIndexRequest;
use App\Http\Resources\ProductCategoryResource;
use App\Http\Resources\ProductResource;
use App\Http\Resources\SkinConcernResource;
use App\Http\Resources\SkinTypeResource;
use App\Models\Product;
use App\Models\ProductCategory;
use App\Models\SkinConcern;
use App\Models\SkinType;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;

class CatalogController extends Controller
{
    public function skinTypes(): AnonymousResourceCollection
    {
        return SkinTypeResource::collection(
            SkinType::query()
                ->where('is_active', true)
                ->orderBy('sort_order')
                ->orderBy('name')
                ->get(),
        );
    }

    public function skinConcerns(): AnonymousResourceCollection
    {
        return SkinConcernResource::collection(
            SkinConcern::query()
                ->where('is_active', true)
                ->orderBy('sort_order')
                ->orderBy('name')
                ->get(),
        );
    }

    public function productCategories(): AnonymousResourceCollection
    {
        return ProductCategoryResource::collection(
            ProductCategory::query()
                ->where('is_active', true)
                ->orderBy('sort_order')
                ->orderBy('name')
                ->get(),
        );
    }

    public function products(ProductIndexRequest $request): AnonymousResourceCollection
    {
        $filters = $request->validated();

        $products = Product::query()
            ->with(['category', 'skinTypes', 'skinConcerns'])
            ->where('is_active', true)
            ->when($filters['category'] ?? null, function ($query, string $slug): void {
                $query->whereHas('category', fn ($categoryQuery) => $categoryQuery->where('slug', $slug));
            })
            ->when($filters['skin_type'] ?? null, function ($query, string $slug): void {
                $query->whereHas('skinTypes', fn ($skinTypeQuery) => $skinTypeQuery->where('slug', $slug));
            })
            ->when($filters['concern'] ?? null, function ($query, string $slug): void {
                $query->whereHas('skinConcerns', fn ($concernQuery) => $concernQuery->where('slug', $slug));
            })
            ->when($filters['search'] ?? null, function ($query, string $search): void {
                $query->where(function ($searchQuery) use ($search): void {
                    $searchQuery
                        ->where('name', 'like', '%'.$search.'%')
                        ->orWhere('brand', 'like', '%'.$search.'%');
                });
            })
            ->orderBy('name')
            ->paginate($filters['per_page'] ?? 15);

        return ProductResource::collection($products);
    }

    public function product(Product $product): ProductResource
    {
        abort_unless($product->is_active, 404);

        return ProductResource::make(
            $product->load(['category', 'skinTypes', 'skinConcerns']),
        );
    }
}
