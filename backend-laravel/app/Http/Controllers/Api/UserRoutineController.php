<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Resources\UserRoutineResource;
use App\Models\RoutineCheckIn;
use App\Models\SkinAnalysis;
use App\Models\UserRoutine;
use Carbon\Carbon;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Validation\ValidationException;

class UserRoutineController extends Controller
{
    public function show(Request $request): JsonResponse
    {
        $routine = $this->activeRoutine($request)
            ?->load([
                'skinAnalysis.imageRecord',
                'skinAnalysis.trainingSamples',
                'checkIns' => fn ($query) => $query->whereBetween('check_date', [
                    today()->startOfWeek()->toDateString(),
                    today()->endOfWeek()->toDateString(),
                ]),
            ]);

        return response()->json([
            'data' => $routine ? UserRoutineResource::make($routine) : null,
        ]);
    }

    public function start(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'skin_analysis_id' => ['required', 'integer'],
        ]);

        $analysis = SkinAnalysis::query()
            ->whereBelongsTo($request->user())
            ->findOrFail($validated['skin_analysis_id']);

        $routinePayload = $analysis->raw_result['treatment_package'] ?? null;
        $needsRetake = (bool) ($analysis->raw_result['scan_quality']['needs_retake'] ?? false);

        if ($needsRetake) {
            throw ValidationException::withMessages([
                'skin_analysis_id' => 'This scan quality is too low to start a routine. Please retake with better lighting and framing.',
            ]);
        }

        if (! is_array($routinePayload)) {
            throw ValidationException::withMessages([
                'skin_analysis_id' => 'This scan does not have a routine plan.',
            ]);
        }

        UserRoutine::query()
            ->whereBelongsTo($request->user())
            ->where('is_active', true)
            ->update(['is_active' => false]);

        $routine = UserRoutine::query()->create([
            'user_id' => $request->user()->id,
            'skin_analysis_id' => $analysis->id,
            'routine_payload' => $routinePayload,
            'is_active' => true,
            'started_at' => now(),
        ]);

        return UserRoutineResource::make(
            $routine->load([
                'skinAnalysis.imageRecord',
                'skinAnalysis.trainingSamples',
                'checkIns' => fn ($query) => $query->whereBetween('check_date', [
                    today()->startOfWeek()->toDateString(),
                    today()->endOfWeek()->toDateString(),
                ]),
            ]),
        )
            ->response()
            ->setStatusCode(201);
    }

    public function updateToday(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'morning_done' => ['sometimes', 'boolean'],
            'night_done' => ['sometimes', 'boolean'],
            'check_date' => ['sometimes', 'date'],
        ]);

        $routine = $this->activeRoutine($request);

        if ($routine === null) {
            return response()->json(['message' => 'No active routine found.'], 404);
        }

        $checkDate = isset($validated['check_date'])
            ? Carbon::parse($validated['check_date'])->toDateString()
            : today()->toDateString();

        $checkIn = RoutineCheckIn::query()->firstOrCreate([
            'user_routine_id' => $routine->id,
            'check_date' => $checkDate,
        ]);

        foreach (['morning_done', 'night_done'] as $field) {
            if (! array_key_exists($field, $validated)) {
                continue;
            }

            $timestampField = str_replace('_done', '_completed_at', $field);
            $checkIn->{$field} = (bool) $validated[$field];
            $checkIn->{$timestampField} = $validated[$field] ? now() : null;
        }

        $checkIn->save();

        return UserRoutineResource::make(
            $routine->fresh()->load([
                'skinAnalysis.imageRecord',
                'skinAnalysis.trainingSamples',
                'checkIns' => fn ($query) => $query->whereBetween('check_date', [
                    today()->startOfWeek()->toDateString(),
                    today()->endOfWeek()->toDateString(),
                ]),
            ]),
        )->response();
    }

    public function stop(Request $request): JsonResponse
    {
        $routine = $this->activeRoutine($request);

        if ($routine === null) {
            return response()->json(['message' => 'No active routine found.'], 404);
        }

        $routine->update(['is_active' => false]);

        return response()->json(null, 204);
    }

    private function activeRoutine(Request $request): ?UserRoutine
    {
        return UserRoutine::query()
            ->whereBelongsTo($request->user())
            ->where('is_active', true)
            ->latest('started_at')
            ->first();
    }
}
