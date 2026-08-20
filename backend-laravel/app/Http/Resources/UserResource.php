<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class UserResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'name' => $this->name,
            'email' => $this->email,
            'role' => $this->role,
            'google_id' => $this->google_id,
            'avatar_url' => $this->avatar_url,
            'age_band' => $this->age_band,
            'skin_tone_scale' => $this->skin_tone_scale,
            'skin_goals' => $this->skin_goals ?? [],
            'profile_completed_at' => $this->profile_completed_at?->toISOString(),
        ];
    }
}
