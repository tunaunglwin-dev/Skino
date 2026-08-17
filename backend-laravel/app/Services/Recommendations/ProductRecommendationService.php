<?php

namespace App\Services\Recommendations;

use App\Models\Product;
use Illuminate\Database\Eloquent\Collection;

class ProductRecommendationService
{
    /**
     * @param  array<int, array{name?: string, confidence?: float|int, severity?: string}>  $concerns
     * @return Collection<int, Product>
     */
    public function forAnalysis(?string $skinTypeSlug, array $concerns, int $limit = 5): Collection
    {
        $concernConfidenceBySlug = collect($concerns)
            ->filter(fn (array $concern): bool => isset($concern['name']))
            ->mapWithKeys(fn (array $concern): array => [
                (string) $concern['name'] => (float) ($concern['confidence'] ?? 1),
            ]);

        if ($skinTypeSlug === null && $concernConfidenceBySlug->isEmpty()) {
            return new Collection;
        }

        return Product::query()
            ->with(['category', 'skinTypes', 'skinConcerns'])
            ->where('is_active', true)
            ->where(function ($query) use ($skinTypeSlug, $concernConfidenceBySlug): void {
                if ($skinTypeSlug !== null) {
                    $query->whereHas('skinTypes', fn ($skinTypeQuery) => $skinTypeQuery->where('slug', $skinTypeSlug));
                }

                if ($concernConfidenceBySlug->isNotEmpty()) {
                    $query->orWhereHas(
                        'skinConcerns',
                        fn ($concernQuery) => $concernQuery->whereIn('slug', $concernConfidenceBySlug->keys()),
                    );
                }
            })
            ->get()
            ->sortByDesc(function (Product $product) use ($skinTypeSlug, $concernConfidenceBySlug): float {
                $score = 0;

                if ($skinTypeSlug !== null) {
                    $skinType = $product->skinTypes->firstWhere('slug', $skinTypeSlug);
                    $score += (float) ($skinType?->pivot?->recommendation_weight ?? 0);
                }

                foreach ($product->skinConcerns as $concern) {
                    $confidence = $concernConfidenceBySlug->get($concern->slug);

                    if ($confidence !== null) {
                        $score += ((float) $concern->pivot->recommendation_weight) * $confidence;
                    }
                }

                return $score;
            })
            ->take($limit)
            ->values();
    }
}
