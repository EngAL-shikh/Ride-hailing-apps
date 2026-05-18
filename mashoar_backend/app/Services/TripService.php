<?php

namespace App\Services;

use App\Models\Trip;
use App\Models\TripBid;
use App\Models\User;
use App\Traits\FirebaseSync;
use Illuminate\Support\Facades\DB;

class TripService
{
    use FirebaseSync;
    public function requestTrip(User $rider, array $data): Trip
    {
        $trip = Trip::query()->create([
            'rider_id' => $rider->id,
            'pickup_lat' => (float) $data['pickup_lat'],
            'pickup_lng' => (float) $data['pickup_lng'],
            'dropoff_lat' => (float) $data['dropoff_lat'],
            'dropoff_lng' => (float) $data['dropoff_lng'],
            'offered_price' => isset($data['offered_price']) ? (float) $data['offered_price'] : null,
            'status' => 'bidding',
        ]);

        // Sync to Firebase RTDB for real-time updates
        $this->syncTripToFirebase($trip);

        return $trip;
    }

    public function placeBid(User $driver, Trip $trip, float $amount): TripBid
    {
        $bid = TripBid::query()->updateOrCreate(
            ['trip_id' => $trip->id, 'driver_id' => $driver->id],
            ['amount' => $amount, 'status' => 'pending']
        );

        // Sync bid to Firebase RTDB for real-time updates
        $this->syncBidToFirebase($bid, $driver);

        // Also update bids_count in the main trip node
        $trip->refresh();
        $bidsCount = $trip->bids()->count();
        $this->updateFirebaseNode("trips/{$trip->id}", [
            'bids_count' => $bidsCount,
        ]);

        return $bid;
    }

    public function acceptBid(Trip $trip, TripBid $bid, float $commissionRate): Trip
    {
        return DB::transaction(function () use ($trip, $bid, $commissionRate) {
            $trip->refresh();

            if ($trip->status !== 'bidding') {
                throw new \RuntimeException('trip_not_biddable');
            }

            $trip->driver_id = $bid->driver_id;
            $trip->accepted_price = (float) $bid->amount;
            $trip->commission_rate = $commissionRate;
            $trip->status = 'assigned';
            $trip->accepted_at = now();
            $trip->save();

            TripBid::query()
                ->where('trip_id', $trip->id)
                ->where('id', '!=', $bid->id)
                ->update(['status' => 'rejected']);

            $bid->status = 'accepted';
            $bid->save();

            // Sync trip status change to Firebase RTDB
            $this->syncTripToFirebase($trip->fresh(['driver', 'rider']));
            
            // Remove from available trips (if exists)
            $this->deleteFirebaseNode("trips/available/{$trip->id}");

            return $trip;
        });
    }

    public function notifyArrival(Trip $trip): Trip
    {
        $trip->refresh();

        if ($trip->status !== 'assigned') {
            throw new \RuntimeException('trip_not_assigned');
        }

        $trip->status = 'arrived';
        $trip->save();

        // Sync trip status change to Firebase RTDB
        $this->syncTripToFirebase($trip->fresh(['driver', 'rider']));

        return $trip;
    }

    public function startTrip(Trip $trip): Trip
    {
        $trip->refresh();

        if (!in_array($trip->status, ['assigned', 'arrived'], true)) {
            throw new \RuntimeException('trip_not_startable');
        }

        $trip->status = 'in_progress';
        $trip->save();

        // Sync trip status change to Firebase RTDB
        $this->syncTripToFirebase($trip->fresh(['driver', 'rider']));

        return $trip;
    }

    public function completeTrip(Trip $trip): Trip
    {
        $trip->refresh();

        if (! in_array($trip->status, ['assigned', 'in_progress'], true)) {
            throw new \RuntimeException('trip_not_completable');
        }

        $trip->status = 'completed';
        $trip->completed_at = now();
        $trip->save();

        // Sync trip status change to Firebase RTDB
        $this->syncTripToFirebase($trip->fresh(['driver', 'rider']));

        return $trip;
    }

    /**
     * Sync trip data to Firebase RTDB at /trips/{trip_id}.
     */
    protected function syncTripToFirebase(Trip $trip): void
    {
        $trip->loadMissing(['rider', 'driver']);

        $data = [
            'id' => $trip->id,
            'rider_id' => $trip->rider_id,
            'driver_id' => $trip->driver_id,
            'pickup_lat' => (float) $trip->pickup_lat,
            'pickup_lng' => (float) $trip->pickup_lng,
            'dropoff_lat' => (float) $trip->dropoff_lat,
            'dropoff_lng' => (float) $trip->dropoff_lng,
            'offered_price' => $trip->offered_price ? (float) $trip->offered_price : null,
            'accepted_price' => $trip->accepted_price ? (float) $trip->accepted_price : null,
            'status' => $trip->status,
            'created_at' => $trip->created_at?->toIso8601String(),
            'updated_at' => $trip->updated_at?->toIso8601String(),
        ];

        if ($trip->rider) {
            $data['rider'] = [
                'id' => $trip->rider->id,
                'name' => $trip->rider->name,
                'phone' => $trip->rider->phone,
            ];
        }

        if ($trip->driver) {
            $data['driver'] = [
                'id' => $trip->driver->id,
                'name' => $trip->driver->name,
                'phone' => $trip->driver->phone,
            ];
        }

        $this->updateFirebaseNode("trips/{$trip->id}", $data);
    }

    /**
     * Sync bid data to Firebase RTDB at /trips/{trip_id}/bids/{driver_id}.
     */
    protected function syncBidToFirebase(TripBid $bid, User $driver): void
    {
        $data = [
            'id' => $bid->id,
            'driver_id' => $bid->driver_id,
            'amount' => (float) $bid->amount,
            'status' => $bid->status,
            'created_at' => $bid->created_at?->toIso8601String(),
            'updated_at' => $bid->updated_at?->toIso8601String(),
            'driver' => [
                'id' => $driver->id,
                'name' => $driver->name,
                'phone' => $driver->phone,
            ],
        ];

        $this->updateFirebaseNode("trips/{$bid->trip_id}/bids/{$bid->driver_id}", $data);
    }
}
