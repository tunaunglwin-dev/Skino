<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Resources\CrmRecordResource;
use App\Models\Contact;
use App\Models\CrmRecord;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Str;
use Illuminate\Validation\Rule;

class AppointmentRequestController extends Controller
{
    public function store(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'name' => ['nullable', 'string', 'max:120'],
            'email' => ['nullable', 'required_without:phone', 'email', 'max:255'],
            'phone' => ['nullable', 'required_without:email', 'string', 'max:40'],
            'preferred_contact_method' => ['nullable', Rule::in(['phone', 'email', 'viber', 'telegram', 'in_app'])],
            'preferred_date' => ['nullable', 'date', 'after_or_equal:today'],
            'requested_specialist' => ['nullable', 'string', 'max:120'],
            'beauty_goal' => ['nullable', 'string', 'max:160'],
            'concern_summary' => ['nullable', 'string', 'max:2000'],
            'skin_analysis_id' => ['nullable', 'integer'],
            'skin_type' => ['nullable', 'string', 'max:60'],
            'acne_severity' => ['nullable', 'string', 'max:40'],
            'skin_health_score' => ['nullable', 'integer', 'min:0', 'max:100'],
            'notes' => ['nullable', 'string', 'max:2000'],
        ]);

        if (! $request->user() && empty($validated['name'])) {
            return response()->json([
                'message' => 'The name field is required.',
                'errors' => ['name' => ['The name field is required.']],
            ], 422);
        }

        $contact = $this->resolveContact($request, $validated);
        $severity = strtolower((string) ($validated['acne_severity'] ?? 'none'));
        $priority = match ($severity) {
            'severe' => CrmRecord::PRIORITY_URGENT,
            'moderate' => CrmRecord::PRIORITY_HIGH,
            default => CrmRecord::PRIORITY_NORMAL,
        };
        $scheduledAt = $validated['preferred_date'] ?? null;
        $specialist = $this->resolveSpecialist($validated['requested_specialist'] ?? null);

        $record = CrmRecord::query()->create([
            'contact_id' => $contact->id,
            'specialist_contact_id' => $specialist?->id,
            'title' => $this->appointmentTitle($contact, $severity),
            'stage' => $scheduledAt ? CrmRecord::STAGE_APPOINTMENT : CrmRecord::STAGE_NEW,
            'priority' => $priority,
            'source' => 'mobile_app',
            'appointment_status' => $scheduledAt
                ? CrmRecord::APPOINTMENT_SCHEDULED
                : CrmRecord::APPOINTMENT_NOT_SCHEDULED,
            'scheduled_at' => $scheduledAt,
            'beauty_goal' => $validated['beauty_goal'] ?? 'Specialist skincare consultation',
            'concern_summary' => $this->concernSummary($validated),
            'tags' => array_values(array_filter([
                'appointment-request',
                $specialist ? 'specialist-'.$specialist->id : null,
                $severity !== 'none' ? $severity : null,
                $validated['skin_type'] ?? null,
            ])),
        ]);

        return CrmRecordResource::make($record->load(['contact.user', 'specialist', 'owner', 'notes.author']))
            ->response()
            ->setStatusCode(201);
    }

    /**
     * @param  array<string, mixed>  $validated
     */
    private function resolveContact(Request $request, array $validated): Contact
    {
        $user = $request->user();

        if ($user) {
            return Contact::query()->updateOrCreate(
                ['user_id' => $user->id],
                [
                    'display_name' => $user->name,
                    'contact_type' => Contact::TYPE_USER,
                    'source' => $user->google_id ? Contact::SOURCE_GOOGLE : Contact::SOURCE_SYSTEM,
                    'status' => Contact::STATUS_ACTIVE,
                    'gmail_email' => $user->google_id ? Str::lower($user->email) : null,
                    'email' => Str::lower($user->email),
                    'phone' => $validated['phone'] ?? null,
                    'avatar_url' => $user->avatar_url,
                    'last_seen_at' => now(),
                ],
            );
        }

        $email = isset($validated['email']) ? Str::lower((string) $validated['email']) : null;
        $phone = $validated['phone'] ?? null;
        $contact = Contact::query()
            ->when($email, fn ($query) => $query->where('email', $email))
            ->when(! $email && $phone, fn ($query) => $query->where('phone', $phone))
            ->first();

        if ($contact) {
            $contact->update([
                'display_name' => $validated['name'] ?? $contact->display_name,
                'phone' => $phone ?? $contact->phone,
                'last_seen_at' => now(),
            ]);

            return $contact;
        }

        return Contact::query()->create([
            'display_name' => $validated['name'],
            'contact_type' => Contact::TYPE_LEAD,
            'source' => Contact::SOURCE_MANUAL,
            'status' => Contact::STATUS_ACTIVE,
            'email' => $email,
            'phone' => $phone,
            'tags' => ['mobile-lead', 'appointment-request'],
            'last_seen_at' => now(),
        ]);
    }

    private function appointmentTitle(Contact $contact, string $severity): string
    {
        $prefix = in_array($severity, ['moderate', 'severe'], true)
            ? Str::title($severity).' acne consultation'
            : 'Specialist consultation request';

        return "{$prefix} - {$contact->display_name}";
    }

    private function resolveSpecialist(?string $name): ?Contact
    {
        $name = trim((string) $name);

        if ($name === '') {
            return null;
        }

        return Contact::query()->firstOrCreate(
            [
                'display_name' => $name,
                'contact_type' => Contact::TYPE_SPECIALIST,
            ],
            [
                'source' => Contact::SOURCE_SYSTEM,
                'status' => Contact::STATUS_ACTIVE,
                'specialty' => 'Mobile appointment requests',
                'tags' => ['mobile-specialist'],
                'last_seen_at' => now(),
            ],
        );
    }

    /**
     * @param  array<string, mixed>  $validated
     */
    private function concernSummary(array $validated): string
    {
        $parts = array_filter([
            isset($validated['skin_type']) ? 'Skin type: '.$validated['skin_type'] : null,
            isset($validated['skin_analysis_id']) ? 'Scan ID: '.$validated['skin_analysis_id'] : null,
            isset($validated['acne_severity']) ? 'Acne severity: '.$validated['acne_severity'] : null,
            isset($validated['skin_health_score']) ? 'Skin score: '.$validated['skin_health_score'] : null,
            isset($validated['preferred_contact_method']) ? 'Preferred contact: '.$validated['preferred_contact_method'] : null,
            isset($validated['requested_specialist']) ? 'Requested specialist: '.$validated['requested_specialist'] : null,
            $validated['concern_summary'] ?? null,
            isset($validated['notes']) ? 'User notes: '.$validated['notes'] : null,
        ]);

        return implode("\n", $parts);
    }
}
