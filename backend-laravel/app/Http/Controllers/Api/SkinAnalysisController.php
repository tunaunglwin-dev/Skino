<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\Analysis\StoreSkinAnalysisRequest;
use App\Http\Resources\SkinAnalysisResource;
use App\Models\SkinAnalysis;
use App\Models\UserRoutine;
use App\Services\Ai\SkinAnalyzer;
use App\Services\Learning\LearningPipelineService;
use App\Services\Recommendations\ProductRecommendationService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;
use RuntimeException;

class SkinAnalysisController extends Controller
{
    public function guestStore(
        StoreSkinAnalysisRequest $request,
        SkinAnalyzer $skinAnalyzer,
    ): JsonResponse {
        $image = $request->file('image');

        try {
            $result = $skinAnalyzer->analyze(
                $image,
                $request->validated('face_landmarks'),
                $request->file('frames', []),
            );
        } catch (RuntimeException) {
            return response()->json([
                'message' => 'Skin analysis service is unavailable.',
            ], 502);
        }

        $result['capture_context'] = $this->captureContext($request);

        return response()->json([
            'data' => [
                'id' => null,
                'skin_type' => $result['skin_type'] ?? null,
                'skin_type_confidence' => $result['skin_type_confidence'] ?? null,
                'concerns' => $result['concerns'] ?? [],
                'skin_zones' => $result['skin_zones'] ?? [],
                'scan_quality' => $result['scan_quality'] ?? null,
                'acne_severity' => $result['acne_severity'] ?? 'none',
                'skin_health_score' => $result['skin_health_score'] ?? null,
                'beauty_routine' => $result['treatment_package'] ?? null,
                'treatment_package' => $result['treatment_package'] ?? null,
                'created_at' => now()->toISOString(),
                'recommended_products' => [],
                'guest_mode' => true,
                'login_required_for' => ['save_history', 'progress_tracking', 'appointments'],
            ],
        ]);
    }

    public function index(Request $request): JsonResponse
    {
        $analyses = SkinAnalysis::query()
            ->whereBelongsTo($request->user())
            ->with(['imageRecord', 'trainingSamples'])
            ->latest()
            ->paginate(min(max((int) $request->integer('per_page', 15), 1), 50));

        return response()->json(SkinAnalysisResource::collection($analyses)->response()->getData(true));
    }

    public function store(
        StoreSkinAnalysisRequest $request,
        SkinAnalyzer $skinAnalyzer,
        ProductRecommendationService $recommendations,
        LearningPipelineService $learningPipeline,
    ): JsonResponse {
        $image = $request->file('image');

        try {
            $result = $skinAnalyzer->analyze(
                $image,
                $request->validated('face_landmarks'),
                $request->file('frames', []),
            );
        } catch (RuntimeException) {
            return response()->json([
                'message' => 'Skin analysis service is unavailable.',
            ], 502);
        }

        $result['capture_context'] = $this->captureContext($request);

        $imagePath = $image->store('skin-analyses/'.$request->user()->id);
        $analysis = SkinAnalysis::query()->create([
            'user_id' => $request->user()->id,
            'image_path' => $imagePath,
            'skin_type_slug' => $result['skin_type'] ?? null,
            'skin_type_confidence' => $result['skin_type_confidence'] ?? null,
            'concerns' => $result['concerns'] ?? [],
            'acne_severity' => $result['acne_severity'] ?? 'none',
            'skin_health_score' => $result['skin_health_score'] ?? null,
            'ai_provider' => 'skin-ai-service',
            'raw_result' => $result,
        ]);
        $learningPipeline->recordImage(
            $request->user(),
            $analysis,
            $image,
            $imagePath,
            $request->boolean('allow_model_training'),
        );
        $analysis->load(['imageRecord', 'trainingSamples']);

        $analysis->setRelation(
            'recommendedProducts',
            $recommendations->forAnalysis($analysis->skin_type_slug, $analysis->concerns ?? []),
        );

        return SkinAnalysisResource::make($analysis)
            ->response()
            ->setStatusCode(201);
    }

    public function show(Request $request, SkinAnalysis $skinAnalysis, ProductRecommendationService $recommendations): JsonResponse
    {
        abort_unless($skinAnalysis->user()->is($request->user()), 404);

        $skinAnalysis->setRelation(
            'recommendedProducts',
            $recommendations->forAnalysis($skinAnalysis->skin_type_slug, $skinAnalysis->concerns ?? []),
        );

        return SkinAnalysisResource::make($skinAnalysis->load(['imageRecord', 'trainingSamples']))->response();
    }

    public function destroy(Request $request, SkinAnalysis $skinAnalysis): JsonResponse
    {
        abort_unless($skinAnalysis->user()->is($request->user()), 404);

        $isActiveRoutineSource = UserRoutine::query()
            ->where('user_id', $request->user()->id)
            ->where('skin_analysis_id', $skinAnalysis->id)
            ->where('is_active', true)
            ->exists();

        if ($isActiveRoutineSource) {
            return response()->json([
                'message' => 'This scan is used by your active routine. Stop or replace the routine before deleting this scan.',
            ], 409);
        }

        if ($skinAnalysis->image_path !== null) {
            Storage::delete($skinAnalysis->image_path);
        }

        $skinAnalysis->delete();

        return response()->json(null, 204);
    }

    /**
     * @return array<string, int|float|string>
     */
    private function captureContext(StoreSkinAnalysisRequest $request): array
    {
        return [
            'mode' => (string) ($request->validated('capture_mode') ?? 'single_upload'),
            'frame_count' => (int) ($request->validated('frame_count') ?? 1),
            'client_quality_score' => round((float) ($request->validated('client_quality_score') ?? 0), 2),
            'device_category' => (string) ($request->validated('device_category') ?? 'unknown'),
        ];
    }
}
