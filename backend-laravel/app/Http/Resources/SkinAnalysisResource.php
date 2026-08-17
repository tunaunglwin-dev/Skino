<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class SkinAnalysisResource extends JsonResource
{
    /**
     * Transform the resource into an array.
     *
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'skin_type' => $this->skin_type_slug,
            'skin_type_confidence' => $this->skin_type_confidence,
            'concerns' => $this->concerns ?? [],
            'skin_zones' => $this->raw_result['skin_zones'] ?? [],
            'scan_quality' => $this->raw_result['scan_quality'] ?? null,
            'acne_severity' => $this->acne_severity ?? 'none',
            'skin_health_score' => $this->skin_health_score,
            'treatment_package' => $this->raw_result['treatment_package'] ?? null,
            'created_at' => $this->created_at?->toISOString(),
            'recommended_products' => ProductResource::collection($this->whenLoaded('recommendedProducts')),
            'privacy' => [
                'image_privacy_status' => $this->whenLoaded('imageRecord', fn () => $this->imageRecord?->privacy_status),
                'training_queued' => $this->whenLoaded('trainingSamples', fn () => $this->trainingSamples->isNotEmpty()),
            ],
        ];
    }
}
