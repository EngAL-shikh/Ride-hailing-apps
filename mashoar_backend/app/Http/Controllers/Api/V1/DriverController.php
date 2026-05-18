<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Requests\Driver\PulseRequest;
use App\Http\Requests\Drivers\NearbyDriversRequest;
use App\Http\Resources\DriverResource;
use App\Models\DriverProfile;
use App\Services\DiscoveryService;
use Illuminate\Http\JsonResponse;

class DriverController extends Controller
{
    /**
     * Driver heartbeat + location update.
     */
    public function pulse(PulseRequest $request): JsonResponse
    {
        $user = $request->user();
        if (! $user || $user->type !== 'driver') {
            return response()->json(['message' => 'forbidden'], 403);
        }

        $lat = (float) $request->input('lat');
        $lng = (float) $request->input('lng');
        $isOnline = $request->boolean('is_online', true);

        $profile = DriverProfile::query()->updateOrCreate(
            ['user_id' => $user->id],
            [
                'last_lat' => $lat,
                'last_lng' => $lng,
                'last_seen_at' => now(),
                'is_online' => $isOnline,
            ]
        );

        return response()->json([
            'message' => 'pulse_ok',
            'driver_id' => $user->id,
            'is_online' => (bool) $profile->is_online,
            'last_seen_at' => optional($profile->last_seen_at)->toISOString(),
        ]);
    }

    /**
     * Nearby drivers discovery (rider-side).
     */
    public function nearby(NearbyDriversRequest $request, DiscoveryService $discovery): JsonResponse
    {
        $lat = (float) $request->input('lat');
        $lng = (float) $request->input('lng');
        $radiusKm = $request->has('radius_km') ? (float) $request->input('radius_km') : null;
        $limit = $request->has('limit') ? (int) $request->input('limit') : null;

        $drivers = $discovery->nearbyDrivers($lat, $lng, $radiusKm, $limit);

        return response()->json([
            'data' => DriverResource::collection($drivers),
        ]);
    }
}
