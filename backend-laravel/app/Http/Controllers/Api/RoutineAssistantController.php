<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Services\Ai\RoutineAssistant;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use RuntimeException;

class RoutineAssistantController extends Controller
{
    public function store(Request $request, RoutineAssistant $assistant): JsonResponse
    {
        $validated = $request->validate([
            'message' => ['required', 'string', 'max:500'],
            'context' => ['nullable', 'array'],
            'context.scan' => ['nullable', 'array'],
            'context.routine' => ['nullable', 'array'],
        ]);

        try {
            $reply = $assistant->reply(
                $validated['message'],
                $validated['context'] ?? [],
            );
        } catch (RuntimeException $exception) {
            return response()->json([
                'message' => $exception->getMessage(),
            ], str_contains($exception->getMessage(), 'not configured') ? 503 : 502);
        }

        return response()->json([
            'data' => [
                'reply' => $reply,
            ],
        ]);
    }
}
