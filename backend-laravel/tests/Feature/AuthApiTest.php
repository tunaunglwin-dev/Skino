<?php

namespace Tests\Feature;

use App\Enums\UserRole;
use App\Models\User;
use Illuminate\Auth\Notifications\ResetPassword;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Notification;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class AuthApiTest extends TestCase
{
    use RefreshDatabase;

    public function test_user_can_register_and_receive_token(): void
    {
        $response = $this->postJson('/api/auth/register', [
            'name' => 'Mobile User',
            'email' => 'mobile@example.com',
            'password' => 'Secure123',
            'password_confirmation' => 'Secure123',
        ]);

        $response
            ->assertCreated()
            ->assertJsonPath('data.user.email', 'mobile@example.com')
            ->assertJsonPath('data.user.role', UserRole::User->value)
            ->assertJsonStructure(['data' => ['token', 'token_type']]);

        $this->assertDatabaseHas('users', [
            'email' => 'mobile@example.com',
            'role' => UserRole::User->value,
        ]);
    }

    public function test_user_can_login_and_fetch_profile(): void
    {
        User::factory()->create([
            'email' => 'mobile@example.com',
            'password' => 'Secure123',
        ]);

        $login = $this->postJson('/api/auth/login', [
            'email' => 'mobile@example.com',
            'password' => 'Secure123',
        ]);

        $token = $login->assertOk()->json('data.token');

        $this->withHeader('Authorization', 'Bearer '.$token)
            ->getJson('/api/me')
            ->assertOk()
            ->assertJsonPath('data.email', 'mobile@example.com');
    }

    public function test_invalid_login_is_rejected(): void
    {
        User::factory()->create([
            'email' => 'mobile@example.com',
            'password' => 'Secure123',
        ]);

        $this->postJson('/api/auth/login', [
            'email' => 'mobile@example.com',
            'password' => 'Wrong123',
        ])->assertUnprocessable();
    }

    public function test_authenticated_user_can_logout_current_token(): void
    {
        $user = User::factory()->create();
        $token = $user->createToken('mobile')->plainTextToken;

        $this->withHeader('Authorization', 'Bearer '.$token)
            ->postJson('/api/auth/logout')
            ->assertOk();

        $this->assertDatabaseCount('personal_access_tokens', 0);
        $this->app['auth']->forgetGuards();

        $this->withHeader('Authorization', 'Bearer '.$token)
            ->getJson('/api/me')
            ->assertUnauthorized();
    }

    public function test_admin_route_requires_admin_role(): void
    {
        Sanctum::actingAs(User::factory()->create());

        $this->getJson('/api/admin/me')
            ->assertForbidden();

        Sanctum::actingAs(User::factory()->admin()->create());

        $this->getJson('/api/admin/me')
            ->assertOk()
            ->assertJsonPath('data.role', UserRole::Admin->value);
    }

    public function test_password_reset_link_can_be_requested(): void
    {
        Notification::fake();

        $user = User::factory()->create([
            'email' => 'mobile@example.com',
        ]);

        $this->postJson('/api/auth/forgot-password', [
            'email' => 'mobile@example.com',
        ])->assertOk();

        Notification::assertSentTo($user, ResetPassword::class);
    }

    public function test_password_reset_request_does_not_reveal_unknown_email(): void
    {
        Notification::fake();

        $this->postJson('/api/auth/forgot-password', [
            'email' => 'unknown@example.com',
        ])
            ->assertOk()
            ->assertJsonPath('message', 'If that email has an admin account, a password reset link will be sent.');

        Notification::assertNothingSent();
    }

    public function test_password_can_be_reset_and_existing_tokens_are_revoked(): void
    {
        $user = User::factory()->create([
            'email' => 'mobile@example.com',
            'password' => 'OldSecure123!',
        ]);
        $user->createToken('mobile');

        $token = app('auth.password.broker')->createToken($user);

        $this->postJson('/api/auth/reset-password', [
            'email' => 'mobile@example.com',
            'token' => $token,
            'password' => 'NewSecure123!',
            'password_confirmation' => 'NewSecure123!',
        ])->assertOk();

        $user->refresh();

        $this->assertTrue(Hash::check('NewSecure123!', $user->password));
        $this->assertDatabaseCount('personal_access_tokens', 0);
    }

    public function test_auth_token_cleanup_prunes_expired_records(): void
    {
        $user = User::factory()->create();

        $user->createToken('expired', ['*'], now()->subHours(25));
        $user->createToken('recent-expired', ['*'], now()->subHour());
        $user->createToken('active', ['*'], now()->addHour());

        DB::table('password_reset_tokens')->insert([
            'email' => 'old@example.com',
            'token' => 'token',
            'created_at' => now()->subHours(2),
        ]);

        $this->artisan('auth:prune-tokens')
            ->expectsOutputToContain('Pruned 1 Sanctum token(s) and 1 password reset token(s).')
            ->assertExitCode(0);

        $this->assertDatabaseCount('personal_access_tokens', 2);
        $this->assertDatabaseMissing('password_reset_tokens', [
            'email' => 'old@example.com',
        ]);
    }
}
