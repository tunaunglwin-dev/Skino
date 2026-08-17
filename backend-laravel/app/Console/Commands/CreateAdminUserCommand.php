<?php

namespace App\Console\Commands;

use App\Enums\UserRole;
use App\Models\User;
use Illuminate\Console\Command;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Validator;
use Illuminate\Validation\Rules\Password;
use Illuminate\Validation\ValidationException;

class CreateAdminUserCommand extends Command
{
    protected $signature = 'admin:create
        {--name= : Admin display name}
        {--email= : Admin email address}
        {--password= : Admin password}
        {--force : Update the account if it already exists}';

    protected $description = 'Create or update a guarded admin user account.';

    public function handle(): int
    {
        $name = (string) ($this->option('name') ?: $this->ask('Admin name', 'Platform Admin'));
        $email = strtolower((string) ($this->option('email') ?: $this->ask('Admin email')));
        $password = (string) ($this->option('password') ?: $this->secret('Admin password'));

        try {
            Validator::make(
                ['name' => $name, 'email' => $email, 'password' => $password],
                [
                    'name' => ['required', 'string', 'min:2', 'max:120'],
                    'email' => ['required', 'email:rfc', 'max:255'],
                    'password' => ['required', Password::min(10)->mixedCase()->numbers()->symbols()],
                ],
            )->validate();
        } catch (ValidationException $exception) {
            foreach ($exception->errors() as $messages) {
                foreach ($messages as $message) {
                    $this->error($message);
                }
            }

            return self::FAILURE;
        }

        $existing = User::query()->where('email', $email)->first();

        if ($existing && ! $this->option('force')) {
            $this->error('A user with this email already exists. Re-run with --force to make it an admin.');

            return self::FAILURE;
        }

        User::query()->updateOrCreate(
            ['email' => $email],
            [
                'name' => $name,
                'password' => Hash::make($password),
                'role' => UserRole::Admin,
            ],
        );

        $this->info('Admin user is ready.');

        return self::SUCCESS;
    }
}
