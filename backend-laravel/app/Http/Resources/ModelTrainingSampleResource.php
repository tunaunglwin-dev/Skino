<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class ModelTrainingSampleResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'label_source' => $this->label_source,
            'review_status' => $this->review_status,
            'training_status' => $this->training_status,
            'snapshot_payload' => $this->snapshot_payload,
            'corrected_labels' => $this->corrected_labels,
            'anonymized_metadata' => $this->anonymized_metadata,
            'review_note' => $this->review_note,
            'reviewed_at' => $this->reviewed_at?->toISOString(),
            'exported_at' => $this->exported_at?->toISOString(),
            'analysis' => SkinAnalysisResource::make($this->whenLoaded('analysis')),
            'image' => [
                'id' => $this->image?->id,
                'privacy_status' => $this->image?->privacy_status,
                'mime_type' => $this->image?->mime_type,
                'size_bytes' => $this->image?->size_bytes,
            ],
            'consent' => AiTrainingConsentResource::make($this->whenLoaded('consent')),
            'reviewer' => UserResource::make($this->whenLoaded('reviewer')),
            'created_at' => $this->created_at?->toISOString(),
        ];
    }
}
