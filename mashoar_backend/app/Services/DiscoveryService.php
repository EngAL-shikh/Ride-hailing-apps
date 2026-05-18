<?php

namespace App\Services;

use App\Models\User;
use Illuminate\Support\Collection;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\DB;

class DiscoveryService
{
    public function nearbyDrivers(float $lat, float $lng, ?float $radiusKm = null, ?int $limit = null): Collection
    {
        $settings = Cache::remember('settings:discovery', 300, function () {
            return [
                'radius_km' => (float) config('mashoar.discovery.default_radius_km', 5),
                'limit' => (int) config('mashoar.discovery.default_limit', 20),
                'active_window_seconds' => (int) config('mashoar.discovery.active_window_seconds', 60),
            ];
        });

        $radiusKm = $radiusKm ?: $settings['radius_km'];
        $limit = $limit ?: $settings['limit'];
        $activeWindowSeconds = $settings['active_window_seconds'];

        $baseQuery = User::query()
            ->select([
                'users.id',
                'users.name',
                'users.phone',
                'users.fcm_token',
                'driver_profiles.last_lat',
                'driver_profiles.last_lng',
            ])
            ->join('driver_profiles', 'driver_profiles.user_id', '=', 'users.id')
            ->where('users.type', 'driver')
            ->where('users.is_active', true)
            ->where('driver_profiles.is_online', true)
            ->whereNotNull('driver_profiles.last_lat')
            ->whereNotNull('driver_profiles.last_lng')
            ->where('driver_profiles.last_seen_at', '>=', now()->subSeconds($activeWindowSeconds));

        if (DB::connection()->getDriverName() === 'mysql') {
            $distanceMetersExpr = "ST_Distance_Sphere(POINT(driver_profiles.last_lng, driver_profiles.last_lat), POINT(?, ?))";

            return $baseQuery
                ->addSelect(DB::raw("({$distanceMetersExpr}) / 1000 as distance_km"))
                ->whereRaw("({$distanceMetersExpr}) <= ?", [$lng, $lat, $lng, $lat, $radiusKm * 1000])
                ->orderBy('distance_km')
                ->limit($limit)
                ->get();
        }

        // Fallback (tests on sqlite): compute distance in PHP.
        $candidates = $baseQuery->get();

        return $candidates
            ->map(function ($u) use ($lat, $lng) {
                $u->distance_km = $this->haversineKm($lat, $lng, (float) $u->last_lat, (float) $u->last_lng);
                return $u;
            })
            ->filter(fn ($u) => $u->distance_km <= $radiusKm)
            ->sortBy('distance_km')
            ->take($limit)
            ->values();
    }

    // Haversine formula for approximate distance.
    private function haversineKm(float $lat1, float $lon1, float $lat2, float $lon2): float
    {
        $earthRadiusKm = 6371.0;
        $dLat = deg2rad($lat2 - $lat1);
        $dLon = deg2rad($lon2 - $lon1);

        $a = sin($dLat / 2) ** 2
            + cos(deg2rad($lat1)) * cos(deg2rad($lat2)) * sin($dLon / 2) ** 2;

        $c = 2 * atan2(sqrt($a), sqrt(1 - $a));
        return $earthRadiusKm * $c;
    }
}

