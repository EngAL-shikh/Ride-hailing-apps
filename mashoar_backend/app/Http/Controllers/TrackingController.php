<?php

namespace App\Http\Controllers;

use App\Http\Controllers\Controller;
use Illuminate\Contracts\View\View;

class TrackingController extends Controller
{
    public function show(string $trip_id): View
    {
        $firebase = [
            'apiKey' => env('FIREBASE_API_KEY'),
            'projectId' => env('FIREBASE_PROJECT_ID'),
            'databaseURL' => env('FIREBASE_DATABASE_URL') ?: (env('FIREBASE_PROJECT_ID') ? 'https://'.env('FIREBASE_PROJECT_ID').'-default-rtdb.firebaseio.com' : null),
            'authDomain' => env('FIREBASE_AUTH_DOMAIN') ?: (env('FIREBASE_PROJECT_ID') ? env('FIREBASE_PROJECT_ID').'.firebaseapp.com' : null),
        ];

        return view('tracking', [
            'tripId' => $trip_id,
            'googleMapsKey' => env('GOOGLE_MAPS_JS_API_KEY'),
            'firebase' => $firebase,
        ]);
    }
}
