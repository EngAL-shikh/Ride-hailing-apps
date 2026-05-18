<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Requests\Trips\AcceptBidRequest;
use App\Http\Requests\Trips\CompleteTripRequest;
use App\Http\Requests\Trips\PlaceBidRequest;
use App\Http\Requests\Trips\RequestTripRequest;
use App\Http\Requests\Trips\StartTripRequest;
use App\Http\Resources\TripBidResource;
use App\Http\Resources\TripResource;
use App\Models\Trip;
use App\Models\TripBid;
use App\Services\DiscoveryService;
use App\Services\FcmService;
use App\Services\TripService;
use App\Services\WalletService;
use App\Traits\FirebaseSync;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;

class TripController extends Controller
{
    use FirebaseSync;
    public function request(RequestTripRequest $request, TripService $trips, DiscoveryService $discovery, FcmService $fcm): JsonResponse
    {
        $user = $request->user();
        if (! $user || $user->type !== 'rider') {
            return response()->json(['message' => 'forbidden'], 403);
        }

        $trip = $trips->requestTrip($user, $request->validated());

        // Notify nearby online drivers (FCM) to refresh available trips list.
        $drivers = $discovery->nearbyDrivers((float) $trip->pickup_lat, (float) $trip->pickup_lng);
        $tokens = $drivers
            ->pluck('fcm_token')
            ->filter(fn ($t) => is_string($t) && trim($t) !== '')
            ->values()
            ->all();

        $data = [
            'type' => 'new_trip',
            'trip_id' => (string) $trip->id,
        ];
        if ($trip->offered_price !== null) {
            $data['offered_price'] = (string) $trip->offered_price;
        }

        // FCM: Wake-up notification to nearby drivers (Hybrid Rule: Wake-Up only)
        $fcm->sendToTokens(
            $tokens,
            'رحلة جديدة متاحة',
            'يوجد طلب رحلة جديد بالقرب منك',
            $data
        );

        // RTDB: Add to available trips for real-time updates (Hybrid Rule: Live Flow)
        $trip->loadMissing(['rider']);
        $this->syncAvailableTripToFirebase($trip);

        return response()->json([
            'message' => 'trip_requested',
            'trip' => new TripResource($trip),
        ]);
    }

    public function bid(PlaceBidRequest $request, Trip $trip, TripService $trips, FcmService $fcm): JsonResponse
    {
        $user = $request->user();
        if (! $user || $user->type !== 'driver') {
            return response()->json(['message' => 'forbidden'], 403);
        }

        if ($trip->status !== 'bidding') {
            return response()->json(['message' => 'trip_not_biddable'], 422);
        }

        $bid = $trips->placeBid($user, $trip, (float) $request->input('amount'));

        // FCM: Wake-up notification to rider (optional, RTDB handles live updates)
        $trip->loadMissing('rider');
        $fcm->sendToToken(
            $trip->rider?->fcm_token,
            'مزايدة جديدة',
            'تم استلام مزايدة جديدة على رحلتك',
            [
                'type' => 'new_bid',
                'trip_id' => (string) $trip->id,
                'driver_name' => (string) $user->name,
                'bid_amount' => (string) $bid->amount,
            ]
        );

        // RTDB: Bid is already synced by TripService->placeBid() via syncBidToFirebase()
        // Also update bids_count in /trips/available/{trip_id} for drivers
        $trip->refresh();
        $this->updateFirebaseNode("trips/available/{$trip->id}", [
            'bids_count' => $trip->bids()->count(),
        ]);

        // The rider's app listens to /trips/{trip_id}/bids and sees new bids instantly

        return response()->json([
            'message' => 'bid_placed',
            'bid' => new TripBidResource($bid),
        ]);
    }

    public function accept(AcceptBidRequest $request, Trip $trip, TripService $trips, WalletService $wallets, FcmService $fcm): JsonResponse
    {
        $user = $request->user();
        if (! $user || $user->id !== (int) $trip->rider_id) {
            return response()->json(['message' => 'forbidden'], 403);
        }

        $bid = TripBid::query()
            ->where('trip_id', $trip->id)
            ->where('id', (int) $request->input('bid_id'))
            ->first();

        if (! $bid) {
            return response()->json(['message' => 'bid_not_found'], 404);
        }

        $commissionRate = (float) config('mashoar.trip.commission_rate', 0.15);
        $commissionAmount = (float) $bid->amount * $commissionRate;

        // Debt limit check (projected after commission).
        $driver = $bid->driver;
        if (! $driver) {
            return response()->json(['message' => 'driver_not_found'], 404);
        }

        if (! $wallets->canTakeMoreDebt($driver, -1 * $commissionAmount)) {
            return response()->json(['message' => 'debt_limit_exceeded'], 422);
        }

        try {
            $trip = $trips->acceptBid($trip, $bid, $commissionRate);
        } catch (\RuntimeException $e) {
            return response()->json(['message' => $e->getMessage()], 422);
        }

        // FCM: Wake-up notifications (optional, RTDB handles live updates)
        $driver = $bid->driver;
        $fcm->sendToToken(
            $driver?->fcm_token,
            'تم قبول المزايدة',
            'تم قبول مزايدتك، يمكنك البدء بالرحلة الآن',
            [
                'type' => 'your_bid_accepted',
                'trip_id' => (string) $trip->id,
                'accepted_price' => (string) ($trip->accepted_price ?? $bid->amount),
            ]
        );

        $fcm->sendToToken(
            $user->fcm_token,
            'تم قبول العرض',
            'تم تعيين سائق لرحلتك',
            [
                'type' => 'bid_accepted',
                'trip_id' => (string) $trip->id,
            ]
        );

        // RTDB: Trip status is already synced by TripService->acceptBid() via syncTripToFirebase()
        // Both driver and rider apps listen to /trips/{trip_id} and see status change instantly

        return response()->json([
            'message' => 'bid_accepted',
            'trip' => new TripResource($trip),
        ]);
    }

    public function cancel(Request $request, Trip $trip, TripService $trips, FcmService $fcm): JsonResponse
    {
        $user = $request->user();
        if (!$user) {
            return response()->json(['message' => 'unauthorized'], 401);
        }

        // Only rider or assigned driver can cancel
        $isRider = $user->id === (int) $trip->rider_id;
        $isDriver = $trip->driver_id && $user->id === (int) $trip->driver_id;

        if (!$isRider && !$isDriver) {
            return response()->json(['message' => 'forbidden'], 403);
        }

        // Can only cancel trips that are not completed
        if (in_array($trip->status, ['completed', 'cancelled'])) {
            return response()->json(['message' => 'trip_already_finished'], 422);
        }

        // Update trip status to cancelled
        $trip->status = 'cancelled';
        $trip->save();

        // Sync to RTDB using FirebaseSync trait
        $this->updateFirebaseNode("trips/{$trip->id}", [
            'status' => 'cancelled',
            'updated_at' => now()->toIso8601String(),
        ]);

        // Send FCM notifications
        if ($isRider && $trip->driver_id) {
            // Notify driver that rider cancelled
            $driver = $trip->driver;
            $fcm->sendToToken(
                $driver?->fcm_token,
                'تم إلغاء الرحلة',
                'قام الراكب بإلغاء الرحلة',
                [
                    'type' => 'trip_cancelled',
                    'trip_id' => (string) $trip->id,
                ]
            );
        } elseif ($isDriver) {
            // Notify rider that driver cancelled
            $rider = $trip->rider;
            $fcm->sendToToken(
                $rider?->fcm_token,
                'تم إلغاء الرحلة',
                'قام السائق بإلغاء الرحلة',
                [
                    'type' => 'trip_cancelled',
                    'trip_id' => (string) $trip->id,
                ]
            );
        }

        return response()->json([
            'message' => 'trip_cancelled',
            'trip' => new TripResource($trip),
        ]);
    }

    public function arrival(Trip $trip, TripService $trips, FcmService $fcm): JsonResponse
    {
        $user = request()->user();
        if (!$user || $user->type !== 'driver' || (int)$trip->driver_id !== (int)$user->id) {
            return response()->json(['message' => 'forbidden'], 403);
        }

        try {
            $trip = $trips->notifyArrival($trip);
        } catch (\RuntimeException $e) {
            return response()->json(['message' => $e->getMessage()], 422);
        }

        // FCM: Wake-up notification to rider (optional, RTDB handles live updates)
        $trip->loadMissing('rider');
        $fcm->sendToToken(
            $trip->rider?->fcm_token,
            'السائق وصل',
            'السائق في انتظارك',
            [
                'type' => 'driver_arrived',
                'trip_id' => (string)$trip->id,
            ]
        );

        // RTDB: Trip status is already synced by TripService->notifyArrival() via syncTripToFirebase()
        // Rider app listens to /trips/{trip_id} and sees status change to 'arrived' instantly

        return response()->json([
            'message' => 'driver_arrived',
            'trip' => new TripResource($trip),
        ]);
    }

    public function start(StartTripRequest $request, Trip $trip, TripService $trips, FcmService $fcm): JsonResponse
    {
        $user = $request->user();
        if (! $user || $user->type !== 'driver' || (int) $trip->driver_id !== (int) $user->id) {
            return response()->json(['message' => 'forbidden'], 403);
        }

        try {
            $trip = $trips->startTrip($trip);
        } catch (\RuntimeException $e) {
            return response()->json(['message' => $e->getMessage()], 422);
        }

        // FCM: Wake-up notification to rider (optional, RTDB handles live updates)
        $trip->loadMissing('rider');
        $fcm->sendToToken(
            $trip->rider?->fcm_token,
            'بدأت الرحلة',
            'السائق وصل وبدأت الرحلة',
            [
                'type' => 'trip_started',
                'trip_id' => (string) $trip->id,
            ]
        );

        // RTDB: Trip status is already synced by TripService->startTrip() via syncTripToFirebase()
        // Rider app listens to /trips/{trip_id} and sees status change to 'in_progress' instantly

        return response()->json([
            'message' => 'trip_started',
            'trip' => new TripResource($trip),
        ]);
    }

    public function complete(CompleteTripRequest $request, Trip $trip, TripService $trips, WalletService $wallets, FcmService $fcm): JsonResponse
    {
        $user = $request->user();
        if (! $user || $user->type !== 'driver' || (int) $trip->driver_id !== (int) $user->id) {
            return response()->json(['message' => 'forbidden'], 403);
        }

        try {
            $trip = $trips->completeTrip($trip);
        } catch (\RuntimeException $e) {
            return response()->json(['message' => $e->getMessage()], 422);
        }

        $commissionRate = (float) $trip->commission_rate;
        $acceptedPrice = (float) ($trip->accepted_price ?: 0);
        $commissionAmount = $acceptedPrice * $commissionRate;

        $trip->commission_amount = $commissionAmount;
        $trip->save();

        $wallet = $wallets->applyCommission($user, $trip, $commissionAmount);

        // FCM: Wake-up notification to rider (optional, RTDB handles live updates)
        $trip->loadMissing('rider');
        $fcm->sendToToken(
            $trip->rider?->fcm_token,
            'اكتملت الرحلة',
            'شكراً لاستخدامك مشوار',
            [
                'type' => 'trip_completed',
                'trip_id' => (string) $trip->id,
                'final_price' => (string) ($trip->accepted_price ?? 0),
            ]
        );

        // RTDB: Trip status is already synced by TripService->completeTrip() via syncTripToFirebase()
        // Rider app listens to /trips/{trip_id} and sees completion instantly

        return response()->json([
            'message' => 'trip_completed',
            'trip' => new TripResource($trip),
            'wallet' => [
                'balance' => (float) $wallet->balance,
                'debt_limit' => (float) $wallet->debt_limit,
            ],
        ]);
    }

    public function review(Request $request, Trip $trip): JsonResponse
    {
        $user = $request->user();
        if (!$user || (int)$trip->rider_id !== (int)$user->id) {
            return response()->json(['message' => 'forbidden'], 403);
        }

        $validated = $request->validate([
            'rating' => 'required|integer|min:1|max:5',
            'comment' => 'nullable|string|max:500',
        ]);

        $trip->rating = $validated['rating'];
        $trip->review_comment = $validated['comment'] ?? null;
        $trip->save();

        return response()->json([
            'message' => 'review_submitted',
            'trip' => new TripResource($trip),
        ]);
    }

    public function bids(Trip $trip): JsonResponse
    {
        $user = request()->user();
        if (! $user) {
            return response()->json(['message' => 'forbidden'], 403);
        }

        $isRider = (int) $trip->rider_id === (int) $user->id;
        $isAssignedDriver = $trip->driver_id && (int) $trip->driver_id === (int) $user->id;

        if (! $isRider && ! $isAssignedDriver) {
            return response()->json(['message' => 'forbidden'], 403);
        }

        $bids = $trip->bids()->orderBy('created_at')->get();

        return response()->json([
            'data' => TripBidResource::collection($bids),
        ]);
    }

    public function available(): JsonResponse
    {
        $user = request()->user();
        if (! $user || $user->type !== 'driver') {
            return response()->json(['message' => 'forbidden'], 403);
        }

        // Get trips with status 'bidding' that don't have a driver assigned
        $trips = Trip::query()
            ->where('status', 'bidding')
            ->whereNull('driver_id')
            ->with(['rider', 'bids.driver'])
            ->orderBy('created_at', 'desc')
            ->get();

        return response()->json([
            'message' => 'available_trips',
            'data' => TripResource::collection($trips),
        ]);
    }

    public function my(): JsonResponse
    {
        $user = request()->user();
        if (! $user) {
            return response()->json(['message' => 'forbidden'], 403);
        }

        if ($user->type === 'rider') {
            // Get all trips for this rider
            $trips = Trip::query()
                ->where('rider_id', $user->id)
                ->with(['driver', 'bids.driver'])
                ->orderBy('created_at', 'desc')
                ->get();
        } else {
            // Get all trips for this driver (assigned or with bids)
            $trips = Trip::query()
                ->where(function ($query) use ($user) {
                    $query->where('driver_id', $user->id)
                        ->orWhereHas('bids', function ($q) use ($user) {
                            $q->where('driver_id', $user->id);
                        });
                })
                ->with(['rider', 'bids'])
                ->orderBy('created_at', 'desc')
                ->get();
        }

        return response()->json([
            'message' => 'my_trips',
            'data' => TripResource::collection($trips),
        ]);
    }

    /**
     * Sync trip to Firebase RTDB at /trips/available/{trip_id} for real-time driver updates.
     */
    protected function syncAvailableTripToFirebase(Trip $trip): void
    {
        $trip->loadMissing(['rider', 'bids.driver']);

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

        if ($trip->rider) {
            $data['rider'] = [
                'id' => $trip->rider->id,
                'name' => $trip->rider->name,
                'phone' => $trip->rider->phone,
            ];
        }

        // Always include bids_count (load if not already loaded)
        if (! $trip->relationLoaded('bids')) {
            $trip->load('bids');
        }
        $data['bids_count'] = $trip->bids->count();

        Log::info('[TripController] Syncing available trip to Firebase RTDB', [
            'trip_id' => $trip->id,
            'path' => "trips/available/{$trip->id}",
        ]);
        
        $result = $this->setFirebaseNode("trips/available/{$trip->id}", $data);
        
        if ($result) {
            Log::info('[TripController] ✓ Successfully synced trip to Firebase RTDB', [
                'trip_id' => $trip->id,
            ]);
        } else {
            Log::error('[TripController] ✗ Failed to sync trip to Firebase RTDB', [
                'trip_id' => $trip->id,
                'check_logs' => 'See FirebaseSync logs for details',
            ]);
        }
    }
}
