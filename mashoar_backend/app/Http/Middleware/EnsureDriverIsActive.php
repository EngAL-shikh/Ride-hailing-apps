<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class EnsureDriverIsActive
{
    /**
     * Handle an incoming request.
     *
     * @param  \Closure(\Illuminate\Http\Request): (\Symfony\Component\HttpFoundation\Response)  $next
     */
    public function handle(Request $request, Closure $next): Response
    {
        $user = $request->user();

        // 1. Check if user exists and is a driver
        if (!$user || $user->type !== 'driver') {
            // Allow if this is a generic endpoint used by both types, but if specific to driver logic, block.
            // For now, if not a driver, we mostly ignore unless they try to do driver things.
            // But this middleware should be applied to driver-only routes.
            return $next($request);
        }

        // 2. Check strict Account Active Status (Admin Toggle)
        if (!$user->is_active) {
            return response()->json([
                'message' => 'account_inactive',
                'error' => 'Your account has been deactivated by the administration.'
            ], 403);
        }

        // 3. Check Driver Verification Status
        // Ensure driver profile is loaded
        if (!$user->driverProfile) {
             return response()->json(['message' => 'driver_profile_not_found'], 404);
        }

        if ($user->driverProfile->verification_status !== 'approved') {
            return response()->json([
                'message' => 'driver_not_verified',
                'status' => $user->driverProfile->verification_status,
                'error' => 'Your documents are not yet verified. Please wait for approval.'
            ], 403);
        }

        return $next($request);
    }
}
