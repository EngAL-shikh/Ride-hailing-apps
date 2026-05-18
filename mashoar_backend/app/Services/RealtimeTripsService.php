<?php

namespace App\Services;

use App\Models\Trip;
use Illuminate\Support\Facades\Log;
use Kreait\Firebase\Factory;
use Kreait\Firebase\Database;

/**
 * Service to sync available trips to Firebase Realtime Database
 * for real-time updates without FCM notifications.
 */
class RealtimeTripsService
{
    private ?Database $database = null;

    public function __construct()
    {
        $credentialsPath = (string) config('services.firebase.credentials', '');

        if ($credentialsPath === '' || ! is_file($credentialsPath)) {
            Log::warning('[RealtimeTripsService] Missing firebase credentials, RTDB sync disabled');
            return;
        }

        try {
            $factory = (new Factory())->withServiceAccount($credentialsPath);
            $this->database = $factory->createDatabase();
        } catch (\Throwable $e) {
            Log::error('[RealtimeTripsService] Failed to initialize Firebase Database', [
                'error' => $e->getMessage(),
            ]);
        }
    }

    /**
     * Add or update a trip in Firebase RTDB for real-time availability.
     */
    public function syncTrip(Trip $trip): void
    {
        if ($this->database === null || $trip->status !== 'bidding') {
            return;
        }

        try {
            $ref = $this->database->getReference("trips/available/{$trip->id}");
            
            $data = [
                'id' => $trip->id,
                'rider_id' => $trip->rider_id,
                'pickup_lat' => (float) $trip->pickup_lat,
                'pickup_lng' => (float) $trip->pickup_lng,
                'dropoff_lat' => (float) $trip->dropoff_lat,
                'dropoff_lng' => (float) $trip->dropoff_lng,
                'offered_price' => $trip->offered_price ? (float) $trip->offered_price : null,
                'status' => $trip->status,
                'created_at' => $trip->created_at?->toIso8601String(),
                'updated_at' => $trip->updated_at?->toIso8601String(),
            ];

            // Include rider info if loaded
            if ($trip->relationLoaded('rider') && $trip->rider) {
                $data['rider'] = [
                    'id' => $trip->rider->id,
                    'name' => $trip->rider->name,
                    'phone' => $trip->rider->phone,
                ];
            }

            // Include bids count if loaded
            if ($trip->relationLoaded('bids')) {
                $data['bids_count'] = $trip->bids->count();
            }

            $ref->set($data);
            
            Log::info('[RealtimeTripsService] Synced trip to Firebase RTDB', [
                'trip_id' => $trip->id,
            ]);
        } catch (\Throwable $e) {
            Log::error('[RealtimeTripsService] Failed to sync trip to Firebase RTDB', [
                'trip_id' => $trip->id,
                'error' => $e->getMessage(),
            ]);
        }
    }

    /**
     * Remove a trip from Firebase RTDB (when accepted, cancelled, or expired).
     */
    public function removeTrip(int|string $tripId): void
    {
        if ($this->database === null) {
            return;
        }

        try {
            $ref = $this->database->getReference("trips/available/{$tripId}");
            $ref->remove();
            
            Log::info('[RealtimeTripsService] Removed trip from Firebase RTDB', [
                'trip_id' => $tripId,
            ]);
        } catch (\Throwable $e) {
            Log::error('[RealtimeTripsService] Failed to remove trip from Firebase RTDB', [
                'trip_id' => $tripId,
                'error' => $e->getMessage(),
            ]);
        }
    }

    /**
     * Sync all currently available trips (useful for initial sync or recovery).
     */
    public function syncAllAvailableTrips(): void
    {
        if ($this->database === null) {
            return;
        }

        try {
            $trips = Trip::query()
                ->where('status', 'bidding')
                ->whereNull('driver_id')
                ->with(['rider', 'bids'])
                ->get();

            foreach ($trips as $trip) {
                $this->syncTrip($trip);
            }

            Log::info('[RealtimeTripsService] Synced all available trips', [
                'count' => $trips->count(),
            ]);
        } catch (\Throwable $e) {
            Log::error('[RealtimeTripsService] Failed to sync all available trips', [
                'error' => $e->getMessage(),
            ]);
        }
    }

    /**
     * Clean up old trips from Firebase RTDB (older than specified hours).
     */
    public function cleanupOldTrips(int $hoursOld = 24): void
    {
        if ($this->database === null) {
            return;
        }

        try {
            $cutoffTime = now()->subHours($hoursOld);
            
            $oldTrips = Trip::query()
                ->where('status', 'bidding')
                ->where('created_at', '<', $cutoffTime)
                ->pluck('id');

            foreach ($oldTrips as $tripId) {
                $this->removeTrip($tripId);
            }

            if ($oldTrips->count() > 0) {
                Log::info('[RealtimeTripsService] Cleaned up old trips from Firebase RTDB', [
                    'count' => $oldTrips->count(),
                    'hours_old' => $hoursOld,
                ]);
            }
        } catch (\Throwable $e) {
            Log::error('[RealtimeTripsService] Failed to cleanup old trips', [
                'error' => $e->getMessage(),
            ]);
        }
    }
}
