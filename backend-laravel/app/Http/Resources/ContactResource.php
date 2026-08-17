<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class ContactResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'display_name' => $this->display_name,
            'contact_type' => $this->contact_type,
            'source' => $this->source,
            'status' => $this->status,
            'gmail_email' => $this->gmail_email,
            'email' => $this->email,
            'phone' => $this->phone,
            'avatar_url' => $this->avatar_url,
            'specialty' => $this->specialty,
            'company_name' => $this->company_name,
            'tags' => $this->tags ?? [],
            'internal_note' => $this->internal_note,
            'last_seen_at' => $this->last_seen_at?->toISOString(),
            'user' => UserResource::make($this->whenLoaded('user')),
            'notes' => ContactNoteResource::collection($this->whenLoaded('notes')),
            'created_at' => $this->created_at?->toISOString(),
            'updated_at' => $this->updated_at?->toISOString(),
        ];
    }
}
