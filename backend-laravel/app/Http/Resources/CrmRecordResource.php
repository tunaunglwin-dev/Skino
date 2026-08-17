<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class CrmRecordResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'title' => $this->title,
            'stage' => $this->stage,
            'priority' => $this->priority,
            'source' => $this->source,
            'appointment_status' => $this->appointment_status,
            'scheduled_at' => $this->scheduled_at?->toISOString(),
            'beauty_goal' => $this->beauty_goal,
            'concern_summary' => $this->concern_summary,
            'tags' => $this->tags ?? [],
            'contact' => ContactResource::make($this->whenLoaded('contact')),
            'specialist' => ContactResource::make($this->whenLoaded('specialist')),
            'owner' => UserResource::make($this->whenLoaded('owner')),
            'notes' => CrmNoteResource::collection($this->whenLoaded('notes')),
            'created_at' => $this->created_at?->toISOString(),
            'updated_at' => $this->updated_at?->toISOString(),
        ];
    }
}
