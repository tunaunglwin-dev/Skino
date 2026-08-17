<?php

namespace App\Http\Controllers\Api;

use App\Enums\UserRole;
use App\Http\Controllers\Controller;
use App\Http\Requests\Auth\ForgotPasswordRequest;
use App\Http\Requests\Auth\LoginRequest;
use App\Http\Requests\Auth\RegisterRequest;
use App\Http\Requests\Auth\ResetPasswordRequest;
use App\Models\Contact;
use App\Models\User;
use App\Services\Contacts\ContactSyncService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Password;
use Illuminate\Support\Str;
use Illuminate\Validation\ValidationException;
use Laravel\Sanctum\PersonalAccessToken;
use Laravel\Socialite\Facades\Socialite;

class AuthController extends Controller
{
    public function register(RegisterRequest $request): JsonResponse
    {
        $user = User::query()->create([
            'name' => (string) $request->string('name'),
            'email' => (string) $request->string('email')->lower(),
            'password' => (string) $request->string('password'),
            'role' => UserRole::User,
        ]);
        app(ContactSyncService::class)->syncFromUser($user, Contact::SOURCE_SYSTEM);

        return response()->json([
            'message' => 'Registration successful.',
            'data' => [
                'user' => $user,
                'token' => $this->createAccessToken($user),
                'token_type' => 'Bearer',
            ],
        ], 201);
    }

    public function login(LoginRequest $request): JsonResponse
    {
        $user = User::query()
            ->where('email', (string) $request->string('email')->lower())
            ->first();

        if (! $user || ! Hash::check((string) $request->string('password'), $user->password)) {
            throw ValidationException::withMessages([
                'email' => ['The provided credentials are incorrect.'],
            ]);
        }
        app(ContactSyncService::class)->syncFromUser($user, Contact::SOURCE_SYSTEM);

        return response()->json([
            'message' => 'Login successful.',
            'data' => [
                'user' => $user,
                'token' => $this->createAccessToken($user),
                'token_type' => 'Bearer',
            ],
        ]);
    }

    public function redirectToGoogle(): RedirectResponse
    {
        return Socialite::driver('google')
            ->stateless()
            ->redirect();
    }

    public function handleGoogleCallback(): JsonResponse
    {
        $googleUser = Socialite::driver('google')
            ->stateless()
            ->user();

        return $this->googleSessionFromProfile([
            'sub' => $googleUser->getId(),
            'email' => $googleUser->getEmail(),
            'email_verified' => true,
            'name' => $googleUser->getName() ?: $googleUser->getNickname(),
            'picture' => $googleUser->getAvatar(),
        ]);
    }

    public function googleLogin(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'id_token' => ['required', 'string'],
        ]);

        $response = Http::acceptJson()
            ->timeout(8)
            ->get('https://oauth2.googleapis.com/tokeninfo', [
                'id_token' => $validated['id_token'],
            ]);

        if (! $response->ok()) {
            throw ValidationException::withMessages([
                'id_token' => ['Google could not verify this sign-in token.'],
            ]);
        }

        $googleProfile = $response->json();
        $allowedAudiences = array_filter([
            config('services.google.client_id'),
            config('services.google.mobile_client_id'),
        ]);

        if (! in_array($googleProfile['aud'] ?? null, $allowedAudiences, true)) {
            throw ValidationException::withMessages([
                'id_token' => ['This Google token was issued for a different app.'],
            ]);
        }

        return $this->googleSessionFromProfile($googleProfile);
    }

    public function forgotPassword(ForgotPasswordRequest $request): JsonResponse
    {
        $status = Password::sendResetLink([
            'email' => (string) $request->string('email')->lower(),
        ]);

        if ($status !== Password::RESET_LINK_SENT && $status !== Password::INVALID_USER) {
            throw ValidationException::withMessages([
                'email' => [__($status)],
            ]);
        }

        return response()->json([
            'message' => 'If that email has an admin account, a password reset link will be sent.',
        ]);
    }

    public function resetPassword(ResetPasswordRequest $request): JsonResponse
    {
        $status = Password::reset(
            [
                'email' => (string) $request->string('email')->lower(),
                'token' => (string) $request->string('token'),
                'password' => (string) $request->string('password'),
                'password_confirmation' => (string) $request->string('password_confirmation'),
            ],
            function (User $user, string $password): void {
                $user->forceFill([
                    'password' => $password,
                    'remember_token' => Str::random(60),
                ])->save();

                $user->tokens()->delete();
            },
        );

        if ($status !== Password::PASSWORD_RESET) {
            throw ValidationException::withMessages([
                'email' => [__($status)],
            ]);
        }

        return response()->json([
            'message' => __($status),
        ]);
    }

    public function me(Request $request): JsonResponse
    {
        return response()->json([
            'data' => $request->user(),
        ]);
    }

    public function logout(Request $request): JsonResponse
    {
        $token = $request->user()->currentAccessToken();

        if ($token instanceof PersonalAccessToken) {
            $token->delete();
        } else {
            $request->user()->tokens()->delete();
        }

        return response()->json([
            'message' => 'Logout successful.',
        ]);
    }

    private function createAccessToken(User $user): string
    {
        $expiresAt = $user->isAdmin()
            ? now()->addMinutes((int) config('admin.tokens.expiration_minutes', 480))
            : null;

        return $user
            ->createToken($user->isAdmin() ? 'admin' : 'mobile', ['*'], $expiresAt)
            ->plainTextToken;
    }

    /**
     * @param  array<string, mixed>  $googleProfile
     */
    private function googleSessionFromProfile(array $googleProfile): JsonResponse
    {
        if (($googleProfile['email_verified'] ?? null) !== true
            && ($googleProfile['email_verified'] ?? null) !== 'true') {
            throw ValidationException::withMessages([
                'email' => ['Google account email is not verified.'],
            ]);
        }

        $email = Str::lower((string) ($googleProfile['email'] ?? ''));
        $googleId = (string) ($googleProfile['sub'] ?? '');

        if ($email === '' || $googleId === '') {
            throw ValidationException::withMessages([
                'id_token' => ['Google did not return the required profile fields.'],
            ]);
        }

        $user = User::query()
            ->where('google_id', $googleId)
            ->orWhere('email', $email)
            ->first();

        $profile = [
            'name' => (string) ($googleProfile['name'] ?? Str::before($email, '@')),
            'email' => $email,
            'google_id' => $googleId,
            'avatar_url' => $googleProfile['picture'] ?? null,
        ];

        if ($user) {
            $user->forceFill($profile)->save();
        } else {
            $user = User::query()->create([
                ...$profile,
                'password' => Str::password(32),
                'role' => UserRole::User,
            ]);
        }
        app(ContactSyncService::class)->syncFromUser($user, Contact::SOURCE_GOOGLE);

        return response()->json([
            'message' => 'Google login successful.',
            'data' => [
                'user' => $user,
                'token' => $this->createAccessToken($user),
                'token_type' => 'Bearer',
            ],
        ]);
    }
}
