<?php

namespace App\Http\Middleware;

use App\Enums\UserRole;
use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class EnsureUserHasRole
{
    public function handle(Request $request, Closure $next, string ...$roles): Response
    {
        $user = $request->user();
        $allowedRoles = array_intersect($roles, UserRole::values());

        if (! $user || $allowedRoles === [] || ! in_array($user->role->value, $allowedRoles, true)) {
            return response()->json([
                'message' => 'Forbidden.',
            ], 403);
        }

        return $next($request);
    }
}
