<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\UserRoutine;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;
use Illuminate\Http\Resources\Json\JsonResource;

class AdminCareRoutineController extends Controller
{
    public function index(Request $request): AnonymousResourceCollection
    {
        $validated = $request->validate([
            'search' => ['nullable', 'string', 'max:120'],
            'status' => ['nullable', 'in:active,stopped'],
            'per_page' => ['nullable', 'integer', 'min:1', 'max:50'],
        ]);

        $routines = UserRoutine::query()
            ->with(['user.contact', 'skinAnalysis', 'checkIns'])
            ->when($validated['status'] ?? null, function ($query, string $status): void {
                $query->where('is_active', $status === 'active');
            })
            ->when($validated['search'] ?? null, function ($query, string $search): void {
                $query->whereHas('user', function ($query) use ($search): void {
                    $query
                        ->where('name', 'like', "%{$search}%")
                        ->orWhere('email', 'like', "%{$search}%");
                });
            })
            ->latest('started_at')
            ->paginate($validated['per_page'] ?? 20);

        return JsonResource::collection(
            $routines->through(fn (UserRoutine $routine): array => $this->routinePayload($routine)),
        );
    }

    /**
     * @return array<string, mixed>
     */
    private function routinePayload(UserRoutine $routine): array
    {
        $checkIns = $routine->checkIns;
        $completedDays = $checkIns
            ->filter(fn ($checkIn): bool => (bool) $checkIn->morning_done && (bool) $checkIn->night_done)
            ->count();
        $partialDays = $checkIns
            ->filter(fn ($checkIn): bool => (bool) $checkIn->morning_done xor (bool) $checkIn->night_done)
            ->count();
        $followUpDays = (int) ($routine->routine_payload['follow_up_days'] ?? 14);
        $daysPassed = $routine->started_at ? $routine->started_at->diffInDays(now()) : 0;

        return [
            'id' => $routine->id,
            'is_active' => $routine->is_active,
            'started_at' => $routine->started_at?->toISOString(),
            'follow_up_days' => $followUpDays,
            'follow_up_due_in' => max(0, $followUpDays - $daysPassed),
            'routine' => [
                'name' => $routine->routine_payload['name'] ?? 'Care routine',
                'reason' => $routine->routine_payload['reason'] ?? null,
            ],
            'progress' => [
                'completed_days' => $completedDays,
                'partial_days' => $partialDays,
                'total_check_ins' => $checkIns->count(),
            ],
            'user' => [
                'id' => $routine->user?->id,
                'name' => $routine->user?->name,
                'email' => $routine->user?->email,
                'contact_id' => $routine->user?->contact?->id,
            ],
            'source_scan' => [
                'id' => $routine->skinAnalysis?->id,
                'skin_type' => $routine->skinAnalysis?->skin_type_slug,
                'score' => $routine->skinAnalysis?->skin_health_score,
                'acne_severity' => $routine->skinAnalysis?->acne_severity,
                'needs_retake' => (bool) ($routine->skinAnalysis?->raw_result['scan_quality']['needs_retake'] ?? false),
                'created_at' => $routine->skinAnalysis?->created_at?->toISOString(),
            ],
        ];
    }
}
