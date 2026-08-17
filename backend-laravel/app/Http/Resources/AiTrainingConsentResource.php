<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class AiTrainingConsentResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'consent_type' => $this->consent_type,
            'policy_version' => $this->policy_version,
            'granted' => $this->granted,
            'granted_at' => $this->granted_at?->toISOString(),
            'revoked_at' => $this->revoked_at?->toISOString(),
        ];
    }
}
