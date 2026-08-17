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
}
