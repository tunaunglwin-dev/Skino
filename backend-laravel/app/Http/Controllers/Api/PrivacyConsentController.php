<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Resources\AiTrainingConsentResource;
use App\Models\AiTrainingConsent;
use App\Services\Learning\LearningPipelineService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class PrivacyConsentController extends Controller
{
    public function required(Request $request): JsonResponse
    {
        $records = AiTrainingConsent::query()
            ->where('user_id', $request->user()->id)
            ->whereIn('consent_type', [
                AiTrainingConsent::TYPE_TERMS,
                AiTrainingConsent::TYPE_SCAN_PROCESSING,
            ])
            ->get()
            ->keyBy('consent_type');

        return response()->json([
            'data' => [
                'policy_version' => AiTrainingConsent::REQUIRED_POLICY_VERSION,
                'terms' => $this->consentPayload(
                    $records->get(AiTrainingConsent::TYPE_TERMS),
                    AiTrainingConsent::TYPE_TERMS,
                ),
                'scan_processing' => $this->consentPayload(
                    $records->get(AiTrainingConsent::TYPE_SCAN_PROCESSING),
                    AiTrainingConsent::TYPE_SCAN_PROCESSING,
                ),
                'complete' => $this->isCurrentAndGranted($records->get(AiTrainingConsent::TYPE_TERMS))
                    && $this->isCurrentAndGranted($records->get(AiTrainingConsent::TYPE_SCAN_PROCESSING)),
            ],
        ]);
    }

    public function updateRequired(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'terms' => ['required', 'accepted'],
            'scan_processing' => ['required', 'accepted'],
        ]);

        $now = now();
        $records = collect([
            AiTrainingConsent::TYPE_TERMS => (bool) $validated['terms'],
            AiTrainingConsent::TYPE_SCAN_PROCESSING => (bool) $validated['scan_processing'],
        ])->map(function (bool $granted, string $type) use ($request, $now): AiTrainingConsent {
            return AiTrainingConsent::query()->updateOrCreate(
                ['user_id' => $request->user()->id, 'consent_type' => $type],
                [
                    'policy_version' => AiTrainingConsent::REQUIRED_POLICY_VERSION,
                    'granted' => $granted,
                    'granted_at' => $granted ? $now : null,
                    'revoked_at' => $granted ? null : $now,
                ],
            );
        });

        return response()->json([
            'message' => 'Required privacy choices saved.',
            'data' => [
                'policy_version' => AiTrainingConsent::REQUIRED_POLICY_VERSION,
                'terms' => AiTrainingConsentResource::make($records[AiTrainingConsent::TYPE_TERMS]),
                'scan_processing' => AiTrainingConsentResource::make($records[AiTrainingConsent::TYPE_SCAN_PROCESSING]),
                'complete' => true,
            ],
        ]);
    }

    public function show(Request $request, LearningPipelineService $learningPipeline): JsonResponse
    {
        $consent = $learningPipeline->currentConsent($request->user());

        return response()->json([
            'data' => $consent
                ? AiTrainingConsentResource::make($consent)
                : [
                    'consent_type' => AiTrainingConsent::TYPE_MODEL_TRAINING,
                    'policy_version' => AiTrainingConsent::CURRENT_POLICY_VERSION,
                    'granted' => false,
                    'granted_at' => null,
                    'revoked_at' => null,
                ],
        ]);
    }

    public function update(Request $request, LearningPipelineService $learningPipeline): JsonResponse
    {
        $validated = $request->validate([
            'granted' => ['required', 'boolean'],
        ]);

        $consent = $learningPipeline->setConsent($request->user(), (bool) $validated['granted']);

        return response()->json([
            'message' => $consent->granted
                ? 'Model improvement consent granted.'
                : 'Model improvement consent revoked.',
            'data' => AiTrainingConsentResource::make($consent),
        ]);
    }

    /** @return array<string, mixed> */
    private function consentPayload(?AiTrainingConsent $consent, string $type): array
    {
        if ($consent === null) {
            return [
                'consent_type' => $type,
                'policy_version' => AiTrainingConsent::REQUIRED_POLICY_VERSION,
                'granted' => false,
                'granted_at' => null,
                'revoked_at' => null,
            ];
        }

        return (new AiTrainingConsentResource($consent))->resolve();
    }

    private function isCurrentAndGranted(?AiTrainingConsent $consent): bool
    {
        return $consent?->granted === true
            && $consent->policy_version === AiTrainingConsent::REQUIRED_POLICY_VERSION;
    }
}
