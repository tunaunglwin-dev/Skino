<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\Profile\UpdateUserProfileRequest;
use App\Http\Resources\UserResource;
use App\Services\Contacts\ContactSyncService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class UserProfileController extends Controller
{
    public function show(Request $request): JsonResponse
    {
        return response()->json([
            'data' => UserResource::make($request->user()),
        ]);
    }

    public function update(UpdateUserProfileRequest $request, ContactSyncService $contactSync): JsonResponse
    {
        $user = $request->user();
        $user->forceFill([
            ...$request->safe()->only(['name', 'age_band', 'skin_tone_scale', 'skin_goals']),
            'profile_completed_at' => now(),
        ])->save();
        $contactSync->syncFromUser($user->refresh());

        return response()->json([
            'message' => 'Profile updated.',
            'data' => UserResource::make($user),
        ]);
    }
}
