<?php

use App\Http\Controllers\Api\AdminCareRoutineController;
use App\Http\Controllers\Api\AdminContactController;
use App\Http\Controllers\Api\AdminCrmRecordController;
use App\Http\Controllers\Api\AdminScanReviewController;
use App\Http\Controllers\Api\AdminTrainingSampleController;
use App\Http\Controllers\Api\AppointmentRequestController;
use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\CatalogController;
use App\Http\Controllers\Api\PrivacyConsentController;
use App\Http\Controllers\Api\RoutineAssistantController;
use App\Http\Controllers\Api\SkinAnalysisController;
use App\Http\Controllers\Api\UserProfileController;
use App\Http\Controllers\Api\UserRoutineController;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;

Route::get('/health', function () {
    return response()->json([
        'status' => 'ok',
        'service' => 'skino-laravel',
    ]);
});

Route::prefix('auth')->group(function (): void {
    Route::post('/register', [AuthController::class, 'register'])->middleware('throttle:5,1');
    Route::post('/login', [AuthController::class, 'login'])->middleware('throttle:5,1');
    Route::post('/google', [AuthController::class, 'googleLogin'])->middleware('throttle:10,1');
    Route::get('/google/redirect', [AuthController::class, 'redirectToGoogle'])->middleware('throttle:10,1');
    Route::get('/google/callback', [AuthController::class, 'handleGoogleCallback'])->middleware('throttle:10,1');
    Route::post('/forgot-password', [AuthController::class, 'forgotPassword'])->middleware('throttle:3,1');
    Route::post('/reset-password', [AuthController::class, 'resetPassword'])->middleware('throttle:3,1');

    Route::middleware('auth:sanctum')->group(function (): void {
        Route::post('/logout', [AuthController::class, 'logout']);
    });
});

Route::post('/guest/skin-analysis', [SkinAnalysisController::class, 'guestStore'])
    ->middleware('throttle:20,1');
Route::post('/guest/appointment-requests', [AppointmentRequestController::class, 'store'])
    ->middleware('throttle:10,1');

Route::middleware('auth:sanctum')->group(function (): void {
    Route::get('/me', [AuthController::class, 'me']);
    Route::get('/profile', [UserProfileController::class, 'show']);
    Route::put('/profile', [UserProfileController::class, 'update']);
    Route::get('/privacy/model-training-consent', [PrivacyConsentController::class, 'show']);
    Route::put('/privacy/model-training-consent', [PrivacyConsentController::class, 'update']);
    Route::get('/privacy/required-consents', [PrivacyConsentController::class, 'required']);
    Route::put('/privacy/required-consents', [PrivacyConsentController::class, 'updateRequired']);

    Route::apiResource('skin-analyses', SkinAnalysisController::class)
        ->only(['index', 'store', 'show', 'destroy']);
    Route::get('/routine', [UserRoutineController::class, 'show']);
    Route::post('/routine/start', [UserRoutineController::class, 'start']);
    Route::put('/routine/today', [UserRoutineController::class, 'updateToday']);
    Route::delete('/routine', [UserRoutineController::class, 'stop']);
    Route::post('/chat/routine-assistant', [RoutineAssistantController::class, 'store'])
        ->middleware('throttle:12,1');
    Route::post('/appointment-requests', [AppointmentRequestController::class, 'store'])
        ->middleware('throttle:10,1');

    Route::prefix('catalog')->group(function (): void {
        Route::get('/skin-types', [CatalogController::class, 'skinTypes']);
        Route::get('/skin-concerns', [CatalogController::class, 'skinConcerns']);
        Route::get('/product-categories', [CatalogController::class, 'productCategories']);
        Route::get('/products', [CatalogController::class, 'products']);
        Route::get('/products/{product:slug}', [CatalogController::class, 'product']);
    });

    Route::get('/admin/me', function (Request $request) {
        return response()->json([
            'data' => $request->user(),
        ]);
    })->middleware('role:admin');

    Route::middleware('role:admin')->prefix('admin')->group(function (): void {
        Route::apiResource('contacts', AdminContactController::class)
            ->only(['index', 'store', 'show', 'update']);
        Route::post('/contacts/{contact}/avatar', [AdminContactController::class, 'storeAvatar']);
        Route::post('/contacts/{contact}/notes', [AdminContactController::class, 'storeNote']);
        Route::apiResource('crm-records', AdminCrmRecordController::class)
            ->only(['index', 'store', 'show', 'update']);
        Route::post('/crm-records/{crmRecord}/notes', [AdminCrmRecordController::class, 'storeNote']);
        Route::get('/care-routines', [AdminCareRoutineController::class, 'index']);
        Route::get('/scan-reviews', [AdminScanReviewController::class, 'index']);
        Route::get('/training-samples', [AdminTrainingSampleController::class, 'index']);
        Route::get('/training-samples/{trainingSample}', [AdminTrainingSampleController::class, 'show']);
        Route::post('/training-samples/{trainingSample}/review', [AdminTrainingSampleController::class, 'review']);
    });
});
