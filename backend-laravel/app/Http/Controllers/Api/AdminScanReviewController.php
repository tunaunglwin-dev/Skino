<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\SkinAnalysis;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;
use Illuminate\Http\Resources\Json\JsonResource;

class AdminScanReviewController extends Controller
{
    public function index(Request $request): AnonymousResourceCollection
    {
        $validated = $request->validate([
            'search' => ['nullable', 'string', 'max:120'],
            'quality' => ['nullable', 'in:all,bad,good'],
            'skin_type' => ['nullable', 'string', 'max:80'],
            'per_page' => ['nullable', 'integer', 'min:1', 'max:50'],
        ]);

        $analyses = SkinAnalysis::query()
            ->with(['user.contact', 'imageRecord', 'trainingSamples'])
            ->when($validated['search'] ?? null, function ($query, string $search): void {
                $query->whereHas('user', function ($query) use ($search): void {
                    $query
                        ->where('name', 'like', "%{$search}%")
                        ->orWhere('email', 'like', "%{$search}%");
                });
            })
            ->when($validated['skin_type'] ?? null, fn ($query, string $skinType) => $query->where('skin_type_slug', $skinType))
            ->when(($validated['quality'] ?? 'all') !== 'all', function ($query) use ($validated): void {
                $needsRetake = $validated['quality'] === 'bad';
                $query->where('raw_result->scan_quality->needs_retake', $needsRetake);
            })
            ->latest()
            ->paginate($validated['per_page'] ?? 20);

        return JsonResource::collection(
            $analyses->through(fn (SkinAnalysis $analysis): array => $this->scanPayload($analysis)),
        );
    }

    /**
     * @return array<string, mixed>
     */
    private function scanPayload(SkinAnalysis $analysis): array
    {
        $quality = $analysis->raw_result['scan_quality'] ?? [];
        $concerns = collect($analysis->concerns ?? [])
            ->map(fn ($concern) => is_array($concern) ? ($concern['name'] ?? 'unknown') : $concern)
            ->filter()
            ->take(4)
            ->values();

        return [
            'id' => $analysis->id,
            'skin_type' => $analysis->skin_type_slug,
            'skin_type_confidence' => $analysis->skin_type_confidence,
            'skin_health_score' => $analysis->skin_health_score,
            'acne_severity' => $analysis->acne_severity ?? 'none',
            'concerns' => $concerns,
            'scan_quality' => [
                'needs_retake' => (bool) ($quality['needs_retake'] ?? false),
                'lighting_score' => $quality['lighting_score'] ?? null,
                'face_score' => $quality['face_score'] ?? null,
                'center_score' => $quality['center_score'] ?? null,
                'message' => $quality['message'] ?? null,
            ],
            'privacy' => [
                'image_privacy_status' => $analysis->imageRecord?->privacy_status,
                'training_queued' => $analysis->trainingSamples->isNotEmpty(),
            ],
            'user' => [
                'id' => $analysis->user?->id,
                'name' => $analysis->user?->name,
                'email' => $analysis->user?->email,
                'contact_id' => $analysis->user?->contact?->id,
            ],
            'created_at' => $analysis->created_at?->toISOString(),
        ];
    }
}
