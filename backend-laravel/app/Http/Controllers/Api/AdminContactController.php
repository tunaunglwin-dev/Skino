<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Resources\ContactResource;
use App\Models\Contact;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;
use Illuminate\Support\Facades\Storage;
use Illuminate\Validation\Rule;

class AdminContactController extends Controller
{
    public function index(Request $request): AnonymousResourceCollection
    {
        $validated = $request->validate([
            'search' => ['nullable', 'string', 'max:120'],
            'contact_type' => ['nullable', Rule::in(Contact::types())],
            'status' => ['nullable', Rule::in(Contact::statuses())],
            'source' => ['nullable', Rule::in(Contact::sources())],
        ]);

        $contacts = Contact::query()
            ->with('user')
            ->when($validated['search'] ?? null, function ($query, string $search): void {
                $query->where(function ($query) use ($search): void {
                    $query
                        ->where('display_name', 'like', "%{$search}%")
                        ->orWhere('email', 'like', "%{$search}%")
                        ->orWhere('gmail_email', 'like', "%{$search}%")
                        ->orWhere('phone', 'like', "%{$search}%")
                        ->orWhere('company_name', 'like', "%{$search}%");
                });
            })
            ->when($validated['contact_type'] ?? null, fn ($query, string $type) => $query->where('contact_type', $type))
            ->when($validated['status'] ?? null, fn ($query, string $status) => $query->where('status', $status))
            ->when($validated['source'] ?? null, fn ($query, string $source) => $query->where('source', $source))
            ->latest('updated_at')
            ->paginate(20);

        return ContactResource::collection($contacts);
    }

    public function store(Request $request): JsonResponse
    {
        $contact = Contact::query()->create($this->validatedContact($request));

        return ContactResource::make($contact->load('user'))
            ->response()
            ->setStatusCode(201);
    }

    public function show(Contact $contact): ContactResource
    {
        return ContactResource::make($contact->load(['user', 'notes.author']));
    }

    public function update(Request $request, Contact $contact): ContactResource
    {
        $contact->update($this->validatedContact($request, $contact));

        return ContactResource::make($contact->load(['user', 'notes.author']));
    }

    public function storeNote(Request $request, Contact $contact): JsonResponse
    {
        $validated = $request->validate([
            'note_type' => ['nullable', 'string', 'max:40'],
            'body' => ['required', 'string', 'max:5000'],
        ]);

        $note = $contact->notes()->create([
            'author_id' => $request->user()->id,
            'note_type' => $validated['note_type'] ?? 'general',
            'body' => $validated['body'],
        ]);

        return response()->json([
            'message' => 'Contact note saved.',
            'data' => $note->load('author'),
        ], 201);
    }

    public function storeAvatar(Request $request, Contact $contact): ContactResource|JsonResponse
    {
        if (in_array($contact->contact_type, [Contact::TYPE_USER, Contact::TYPE_LEAD, Contact::TYPE_INTERNAL], true)) {
            return response()->json([
                'message' => 'Avatar uploads are only available for specialist, seller, and vendor contacts.',
            ], 422);
        }

        $validated = $request->validate([
            'avatar' => ['required', 'image', 'mimes:jpg,jpeg,png,webp', 'max:4096'],
        ]);

        $previousPath = $this->publicPathFromUrl($contact->avatar_url);
        if ($previousPath) {
            Storage::disk('public')->delete($previousPath);
        }

        $path = $validated['avatar']->store('contact-avatars', 'public');
        $contact->update([
            'avatar_url' => Storage::disk('public')->url($path),
        ]);

        return ContactResource::make($contact->load(['user', 'notes.author']));
    }

    /**
     * @return array<string, mixed>
     */
    private function validatedContact(Request $request, ?Contact $contact = null): array
    {
        $contactId = $contact?->id;

        $validated = $request->validate([
            'display_name' => ['required', 'string', 'max:120'],
            'contact_type' => ['required', Rule::in(Contact::types())],
            'source' => ['nullable', Rule::in(Contact::sources())],
            'status' => ['nullable', Rule::in(Contact::statuses())],
            'gmail_email' => [
                'nullable',
                'email',
                'max:255',
                Rule::unique('contacts', 'gmail_email')->ignore($contactId),
            ],
            'email' => ['nullable', 'email', 'max:255'],
            'phone' => ['nullable', 'string', 'max:40'],
            'avatar_url' => ['nullable', 'url', 'max:2048'],
            'specialty' => ['nullable', 'string', 'max:120'],
            'company_name' => ['nullable', 'string', 'max:160'],
            'tags' => ['nullable', 'array', 'max:12'],
            'tags.*' => ['string', 'max:40'],
            'internal_note' => ['nullable', 'string', 'max:5000'],
        ]);

        $validated['source'] ??= Contact::SOURCE_MANUAL;
        $validated['status'] ??= Contact::STATUS_ACTIVE;

        if (isset($validated['gmail_email'])) {
            $validated['gmail_email'] = strtolower($validated['gmail_email']);
        }

        if (isset($validated['email'])) {
            $validated['email'] = strtolower($validated['email']);
        }

        return $validated;
    }

    private function publicPathFromUrl(?string $url): ?string
    {
        if (! $url) {
            return null;
        }

        $path = parse_url($url, PHP_URL_PATH);
        if (! is_string($path) || ! str_contains($path, '/storage/')) {
            return null;
        }

        return ltrim(substr($path, strpos($path, '/storage/') + strlen('/storage/')), '/');
    }
}
