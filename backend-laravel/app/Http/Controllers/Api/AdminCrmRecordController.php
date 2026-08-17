<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Resources\CrmRecordResource;
use App\Models\CrmRecord;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;
use Illuminate\Validation\Rule;

class AdminCrmRecordController extends Controller
{
    public function index(Request $request): AnonymousResourceCollection
    {
        $validated = $request->validate([
            'search' => ['nullable', 'string', 'max:120'],
            'stage' => ['nullable', Rule::in(CrmRecord::stages())],
            'priority' => ['nullable', Rule::in(CrmRecord::priorities())],
            'appointment_status' => ['nullable', Rule::in(CrmRecord::appointmentStatuses())],
            'per_page' => ['nullable', 'integer', 'min:1', 'max:50'],
        ]);

        $records = CrmRecord::query()
            ->with(['contact', 'specialist', 'owner'])
            ->when($validated['search'] ?? null, function ($query, string $search): void {
                $query->where(function ($query) use ($search): void {
                    $query
                        ->where('title', 'like', "%{$search}%")
                        ->orWhere('beauty_goal', 'like', "%{$search}%")
                        ->orWhereHas('contact', fn ($contactQuery) => $contactQuery->where('display_name', 'like', "%{$search}%"));
                });
            })
            ->when($validated['stage'] ?? null, fn ($query, string $stage) => $query->where('stage', $stage))
            ->when($validated['priority'] ?? null, fn ($query, string $priority) => $query->where('priority', $priority))
            ->when(
                $validated['appointment_status'] ?? null,
                fn ($query, string $status) => $query->where('appointment_status', $status),
            )
            ->orderBy('scheduled_at')
            ->latest('updated_at')
            ->paginate($validated['per_page'] ?? 20);

        return CrmRecordResource::collection($records);
    }

    public function store(Request $request): JsonResponse
    {
        $record = CrmRecord::query()->create([
            ...$this->validatedRecord($request),
            'owner_id' => $request->user()->id,
        ]);

        return CrmRecordResource::make($record->load(['contact', 'specialist', 'owner', 'notes.author']))
            ->response()
            ->setStatusCode(201);
    }

    public function show(CrmRecord $crmRecord): CrmRecordResource
    {
        return CrmRecordResource::make($crmRecord->load(['contact', 'specialist', 'owner', 'notes.author']));
    }

    public function update(Request $request, CrmRecord $crmRecord): CrmRecordResource
    {
        $crmRecord->update($this->validatedRecord($request));

        return CrmRecordResource::make($crmRecord->load(['contact', 'specialist', 'owner', 'notes.author']));
    }

    public function storeNote(Request $request, CrmRecord $crmRecord): JsonResponse
    {
        $validated = $request->validate([
            'note_type' => ['nullable', 'string', 'max:40'],
            'body' => ['required', 'string', 'max:5000'],
        ]);

        $note = $crmRecord->notes()->create([
            'author_id' => $request->user()->id,
            'note_type' => $validated['note_type'] ?? 'general',
            'body' => $validated['body'],
        ]);

        return response()->json([
            'message' => 'CRM note saved.',
            'data' => $note->load('author'),
        ], 201);
    }

    private function validatedRecord(Request $request): array
    {
        $validated = $request->validate([
            'contact_id' => ['required', 'integer', 'exists:contacts,id'],
            'specialist_contact_id' => ['nullable', 'integer', 'exists:contacts,id'],
            'title' => ['required', 'string', 'max:160'],
            'stage' => ['nullable', Rule::in(CrmRecord::stages())],
            'priority' => ['nullable', Rule::in(CrmRecord::priorities())],
            'source' => ['nullable', 'string', 'max:80'],
            'appointment_status' => ['nullable', Rule::in(CrmRecord::appointmentStatuses())],
            'scheduled_at' => ['nullable', 'date'],
            'beauty_goal' => ['nullable', 'string', 'max:160'],
            'concern_summary' => ['nullable', 'string', 'max:5000'],
            'tags' => ['nullable', 'array', 'max:12'],
            'tags.*' => ['string', 'max:40'],
        ]);

        $validated['stage'] ??= CrmRecord::STAGE_NEW;
        $validated['priority'] ??= CrmRecord::PRIORITY_NORMAL;
        $validated['source'] ??= 'admin';
        $validated['appointment_status'] ??= CrmRecord::APPOINTMENT_NOT_SCHEDULED;

        return $validated;
    }
}
