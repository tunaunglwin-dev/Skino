<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;
use Illuminate\Support\Facades\DB;
use Laravel\Sanctum\PersonalAccessToken;

class PruneAuthTokensCommand extends Command
{
    protected $signature = 'auth:prune-tokens
        {--hours= : Keep expired Sanctum tokens for this many hours before pruning}';

    protected $description = 'Prune expired Sanctum tokens and stale password reset tokens.';

    public function handle(): int
    {
        $hours = (int) ($this->option('hours') ?? config('admin.tokens.prune_hours', 24));
        $resetExpiryMinutes = (int) config('auth.passwords.users.expire', 60);

        $expiredTokens = PersonalAccessToken::query()
            ->whereNotNull('expires_at')
            ->where('expires_at', '<', now()->subHours($hours))
            ->delete();

        $expiredPasswordResetTokens = DB::table(config('auth.passwords.users.table', 'password_reset_tokens'))
            ->where('created_at', '<', now()->subMinutes($resetExpiryMinutes))
            ->delete();

        $this->components->info(sprintf(
            'Pruned %d Sanctum token(s) and %d password reset token(s).',
            $expiredTokens,
            $expiredPasswordResetTokens,
        ));

        return self::SUCCESS;
    }
}
