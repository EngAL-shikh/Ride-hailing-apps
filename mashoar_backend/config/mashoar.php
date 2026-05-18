<?php

return [
    /*
    |--------------------------------------------------------------------------
    | Discovery Settings
    |--------------------------------------------------------------------------
    |
    | Used by read-heavy endpoints. Values are cached via Cache::remember.
    |
    */
    'discovery' => [
        'default_radius_km' => (float) env('DISCOVERY_RADIUS_KM', 5),
        'default_limit' => (int) env('DISCOVERY_LIMIT', 20),
        // Consider a driver "active" if last_seen_at within this window.
        'active_window_seconds' => (int) env('DRIVER_ACTIVE_WINDOW_SECONDS', 60),
    ],

    'trip' => [
        // Platform commission rate. 0.15 means 15%.
        'commission_rate' => (float) env('TRIP_COMMISSION_RATE', 0.15),
        // Max allowed debt. Driver cannot accept/continue if wallet balance is below -debt_limit.
        'default_debt_limit' => (float) env('DRIVER_DEBT_LIMIT', 5000),
    ],
];

