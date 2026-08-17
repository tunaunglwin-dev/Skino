<?php

namespace App\Providers;

use Illuminate\Auth\Notifications\ResetPassword;
use Illuminate\Support\ServiceProvider;
use Illuminate\Support\Str;

class AppServiceProvider extends ServiceProvider
{
    /**
     * Register any application services.
     */
    public function register(): void
    {
        //
    }

    /**
     * Bootstrap any application services.
     */
    public function boot(): void
    {
        ResetPassword::createUrlUsing(function (object $notifiable, string $token): string {
            $baseUrl = rtrim((string) config('admin.frontend_url'), '/');
            $path = '/'.ltrim((string) config('admin.password_reset.frontend_path'), '/');
            $email = urlencode((string) $notifiable->getEmailForPasswordReset());
            $separator = Str::contains($path, '?') ? '&' : '?';

            return "{$baseUrl}{$path}{$separator}token={$token}&email={$email}";
        });
    }
}
