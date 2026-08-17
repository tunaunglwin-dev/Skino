<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Resources\ModelTrainingSampleResource;
use App\Models\ModelTrainingSample;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;
use Illuminate\Validation\Rule;

class AdminTrainingSampleController extends Controller
{
    public function index(Request $request): AnonymousResourceCollection
    {
        $validated = $request->validate([
            'review_status' => [
                'nullable',
                Rule::in([
                    ModelTrainingSample::REVIEW_PENDING,
                    ModelTrainingSample::REVIEW_APPROVED,
                    ModelTrainingSample::REVIEW_REJECTED,
                    ModelTrainingSample::REVIEW_NEEDS_SPECIALIST,
                ]),
            ],
            'training_status' => ['nullable', 'string', 'max:40'],
            'per_page' => ['nullable', 'integer', 'min:1', 'max:50'],
        ]);

        $samples = ModelTrainingSample::query()
            ->with(['analysis.imageRecord', 'image', 'consent', 'reviewer'])
            ->when(
                $validated['review_status'] ?? null,
                fn ($query, string $status) => $query->where('review_status', $status),
            )
            ->when(
                $validated['training_status'] ?? null,
                fn ($query, string $status) => $query->where('training_status', $status),
            )
            ->latest()
            ->paginate($validated['per_page'] ?? 20);

        return ModelTrainingSampleResource::collection($samples);
    }

    public function show(ModelTrainingSample $trainingSample): ModelTrainingSampleResource
    {
        return ModelTrainingSampleResource::make(
            $trainingSample->load(['analysis.imageRecord', 'image', 'consent', 'reviewer']),
        );
    }

    public function review(Request $request, ModelTrainingSample $trainingSample): JsonResponse
    {
        $validated = $request->validate([
            'action' => [
                'required',
                Rule::in(['approve', 'reject', 'correct', 'needs_specialist']),
            ],
            'corrected_labels' => ['nullable', 'array'],
            'corrected_labels.skin_type' => ['nullable', 'string', 'max:80'],
            'corrected_labels.acne_severity' => ['nullable', Rule::in(['none', 'mild', 'moderate', 'severe'])],
            'corrected_labels.concerns' => ['nullable', 'array', 'max:12'],
            'corrected_labels.concerns.*' => ['string', 'max:80'],
            'review_note' => ['nullable', 'string', 'max:3000'],
        ]);

        $reviewStatus = match ($validated['action']) {
            'approve', 'correct' => ModelTrainingSample::REVIEW_APPROVED,
            'reject' => ModelTrainingSample::REVIEW_REJECTED,
            'needs_specialist' => ModelTrainingSample::REVIEW_NEEDS_SPECIALIST,
        };

        $trainingStatus = match ($validated['action']) {
            'approve', 'correct' => ModelTrainingSample::TRAINING_APPROVED,
            'reject' => ModelTrainingSample::TRAINING_EXCLUDED,
            'needs_specialist' => ModelTrainingSample::TRAINING_QUEUED,
        };

        $trainingSample->update([
            'review_status' => $reviewStatus,
            'training_status' => $trainingStatus,
            'corrected_labels' => $validated['corrected_labels'] ?? null,
            'review_note' => $validated['review_note'] ?? null,
            'reviewed_by_id' => $request->user()->id,
            'reviewed_at' => now(),
        ]);

        return response()->json([
            'message' => 'Training sample reviewed.',
            'data' => ModelTrainingSampleResource::make(
                $trainingSample->load(['analysis.imageRecord', 'image', 'consent', 'reviewer']),
            ),
        ]);
    }
}
