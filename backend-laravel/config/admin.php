<?php

return [
    'frontend_url' => env('ADMIN_FRONTEND_URL', 'http://127.0.0.1:5173'),

    'seed' => [
        'enabled' => env('ADMIN_SEED_ENABLED', true),
        'update_existing' => env('ADMIN_SEED_UPDATE_EXISTING', false),
        'name' => env('ADMIN_SEED_NAME', 'Platform Admin'),
        'email' => env('ADMIN_SEED_EMAIL', 'admin@skincare.local'),
        'password' => env('ADMIN_SEED_PASSWORD'),
    ],

    'password_reset' => [
        'frontend_path' => env('ADMIN_PASSWORD_RESET_PATH', '/reset-password'),
    ],

    'tokens' => [
        'expiration_minutes' => env('ADMIN_TOKEN_EXPIRATION_MINUTES', 480),
        'prune_hours' => env('ADMIN_TOKEN_PRUNE_HOURS', 24),
    ],

    'two_factor' => [
        'enabled' => env('ADMIN_2FA_ENABLED', false),
    ],
];
