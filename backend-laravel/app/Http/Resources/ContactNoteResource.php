<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class ContactNoteResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'note_type' => $this->note_type,
            'body' => $this->body,
            'author' => UserResource::make($this->whenLoaded('author')),
            'created_at' => $this->created_at?->toISOString(),
        ];
    }
}
