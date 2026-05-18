# Firebase Realtime Database Setup (Hybrid Architecture)

## Overview
This project uses a **Hybrid Real-Time Architecture**:
- **FCM (Wake-Up)**: Used ONLY for initial "New Ride Request" notifications to wake up drivers
- **Firebase RTDB (Live Flow)**: Used for all real-time updates (Bidding, Acceptance, Status Changes)

## Configuration

### 1. Add to `.env` file:

```env
# Firebase Realtime Database URL
# Format: https://PROJECT_ID-default-rtdb.REGION.firebasedatabase.app
# Get from: Firebase Console > Realtime Database > Data tab > URL
FIREBASE_DB_URL=https://mashoarapp-default-rtdb.asia-southeast1.firebasedatabase.app

# Firebase Database Secret (Legacy Auth - Optional)
# Get from: Firebase Console > Realtime Database > Settings > Service Accounts
# If not provided, the system will attempt to use Service Account token
FIREBASE_DB_SECRET=
```

### 2. Get Firebase Database URL:

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project (`mashoarapp`)
3. Navigate to **Realtime Database**
4. Copy the URL from the **Data** tab (e.g., `https://mashoarapp-default-rtdb.asia-southeast1.firebasedatabase.app`)

### 3. Get Firebase Database Secret (Optional):

1. In Firebase Console > Realtime Database
2. Go to **Settings** tab
3. Scroll to **Service Accounts**
4. Copy the **Database Secret** (if using legacy auth)

**Note**: If you don't provide `FIREBASE_DB_SECRET`, the system will use the Service Account credentials from `FIREBASE_CREDENTIALS` file.

## Architecture Details

### Backend (Laravel)

#### FirebaseSync Trait
- Location: `app/Traits/FirebaseSync.php`
- Uses HTTP REST API (no gRPC) - suitable for shared hosting
- Methods:
  - `updateFirebaseNode()` - PATCH/PUT data to RTDB
  - `deleteFirebaseNode()` - DELETE data from RTDB
  - `setFirebaseNode()` - Replace entire node

#### TripService Integration
- Automatically syncs trip state changes to Firebase RTDB:
  - `requestTrip()` → Creates `/trips/{trip_id}` and `/trips/available/{trip_id}`
  - `placeBid()` → Updates `/trips/{trip_id}/bids/{driver_id}`
  - `acceptBid()` → Updates `/trips/{trip_id}` status and removes from `/trips/available/`
  - `completeTrip()` → Updates `/trips/{trip_id}` status

### Frontend (Flutter)

#### RealtimeTripsService
- Location: `lib/app/core/firebase/realtime_trips_service.dart`
- Streams:
  - `streamAvailableTrips()` - Listens to `/trips/available` (for drivers)
  - `streamTrip(tripId)` - Listens to `/trips/{trip_id}` (for status updates)
  - `streamTripBids(tripId)` - Listens to `/trips/{trip_id}/bids` (for bid updates)

#### Controllers
- **RideController**: Listens to trip status and bids via RTDB
- **DriverController**: Listens to available trips and active trip status via RTDB

## Firebase RTDB Structure

```
trips/
  {trip_id}/
    id: string
    rider_id: int
    driver_id: int (null until accepted)
    pickup_lat: float
    pickup_lng: float
    dropoff_lat: float
    dropoff_lng: float
    offered_price: float (nullable)
    accepted_price: float (nullable)
    status: string (bidding|assigned|in_progress|completed|cancelled)
    rider: { id, name, phone }
    driver: { id, name, phone } (when assigned)
    created_at: ISO8601
    updated_at: ISO8601
    bids/
      {driver_id}/
        id: int
        driver_id: int
        amount: float
        status: string (pending|accepted|rejected)
        driver: { id, name, phone }
        created_at: ISO8601
        updated_at: ISO8601
  available/
    {trip_id}/ (same structure as trips/{trip_id}, but only for bidding trips)
```

## Cost Considerations

### Firebase Realtime Database Free Tier:
- **Storage**: 1 GB
- **Bandwidth**: 10 GB/month
- **Concurrent Connections**: 100

### Estimated Usage (per month):
- **Small App** (10-50 drivers, 100-500 trips/day):
  - Storage: ~50-200 MB
  - Bandwidth: ~1-3 GB
  - **Status**: ✅ Within free tier

- **Medium App** (50-200 drivers, 500-2000 trips/day):
  - Storage: ~200-800 MB
  - Bandwidth: ~3-10 GB
  - **Status**: ⚠️ May exceed free tier (bandwidth)

- **Large App** (200+ drivers, 2000+ trips/day):
  - Storage: 800+ MB
  - Bandwidth: 10+ GB
  - **Status**: ❌ Requires paid plan

### Optimization Tips:
1. **Auto-cleanup**: Old trips are automatically removed from `/trips/available/` when accepted
2. **Minimal Data**: Only essential fields are synced to RTDB
3. **Selective Listening**: Apps only listen to relevant paths (not entire database)

## Testing

### Backend Test:
```bash
php artisan tinker
>>> $trip = App\Models\Trip::first();
>>> $service = new App\Services\TripService();
>>> $service->syncTripToFirebase($trip);
```

### Frontend Test:
- Open driver dashboard
- Create a trip from rider app
- Watch driver dashboard update in real-time (no refresh needed)
- Place a bid from driver app
- Watch rider app update bids list in real-time

## Troubleshooting

### Issue: RTDB updates not working
1. Check `.env` has `FIREBASE_DB_URL` set correctly
2. Check Laravel logs: `storage/logs/laravel.log`
3. Verify Firebase credentials file exists and is readable
4. Test HTTP connection: `curl -X GET "$FIREBASE_DB_URL/.json?auth=$FIREBASE_DB_SECRET"`

### Issue: Flutter streams not receiving updates
1. Check Firebase Realtime Database rules allow read access
2. Verify `DefaultFirebaseOptions.currentPlatform.databaseURL` matches backend URL
3. Check Flutter logs for Firebase connection errors
4. Ensure app has internet permission

## Security Rules

Update Firebase Realtime Database rules to allow read/write:

```json
{
  "rules": {
    "trips": {
      ".read": true,
      ".write": true
    }
  }
}
```

**Note**: For production, implement proper authentication-based rules.
