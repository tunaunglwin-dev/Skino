<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class ProductResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'sku' => $this->sku,
            'slug' => $this->slug,
            'name' => $this->name,
            'brand' => $this->brand,
            'description' => $this->description,
            'price' => $this->price,
            'currency' => $this->currency,
            'image_url' => $this->image_url,
            'category' => ProductCategoryResource::make($this->whenLoaded('category')),
            'skin_types' => SkinTypeResource::collection($this->whenLoaded('skinTypes')),
            'skin_concerns' => SkinConcernResource::collection($this->whenLoaded('skinConcerns')),
        ];
    }
}
