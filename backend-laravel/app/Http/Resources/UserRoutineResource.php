<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class UserRoutineResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        $weekStart = today()->startOfWeek();
        $weekEnd = today()->endOfWeek();
        $loadedCheckIns = $this->relationLoaded('checkIns') ? $this->checkIns : collect();
        $todayCheckIn = $loadedCheckIns->first(
            fn ($checkIn) => $checkIn->check_date?->toDateString() === today()->toDateString(),
        );

        if ($todayCheckIn === null && $this->exists) {
            $todayCheckIn = $this->checkIns()
                ->whereDate('check_date', today()->toDateString())
                ->first();
        }

        $weekCheckIns = collect(range(0, 6))->map(function (int $offset) use ($weekStart, $loadedCheckIns) {
            $date = $weekStart->copy()->addDays($offset);
            $checkIn = $loadedCheckIns->first(
                fn ($item) => $item->check_date?->toDateString() === $date->toDateString(),
            );

            return [
                'date' => $date->toDateString(),
                'label' => $date->format('D'),
                'is_today' => $date->isSameDay(today()),
                'morning_done' => (bool) ($checkIn?->morning_done ?? false),
                'night_done' => (bool) ($checkIn?->night_done ?? false),
                'morning_completed_at' => $checkIn?->morning_completed_at?->toISOString(),
                'night_completed_at' => $checkIn?->night_completed_at?->toISOString(),
            ];
        })->values();

        return [
            'id' => $this->id,
            'skin_analysis_id' => $this->skin_analysis_id,
            'routine' => $this->routine_payload,
            'is_active' => $this->is_active,
            'started_at' => $this->started_at?->toISOString(),
            'today' => [
                'date' => today()->toDateString(),
                'morning_done' => (bool) ($todayCheckIn?->morning_done ?? false),
                'night_done' => (bool) ($todayCheckIn?->night_done ?? false),
                'morning_completed_at' => $todayCheckIn?->morning_completed_at?->toISOString(),
                'night_completed_at' => $todayCheckIn?->night_completed_at?->toISOString(),
            ],
            'week' => [
                'start_date' => $weekStart->toDateString(),
                'end_date' => $weekEnd->toDateString(),
                'check_ins' => $weekCheckIns,
            ],
            'skin_analysis' => SkinAnalysisResource::make($this->whenLoaded('skinAnalysis')),
        ];
    }
}
