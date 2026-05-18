<?php

namespace Tests\Feature;

use App\Models\DriverProfile;
use App\Models\Trip;
use App\Models\User;
use App\Models\Wallet;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class TripBiddingTest extends TestCase
{
    use RefreshDatabase;

    public function test_full_bidding_flow_and_commission_debt(): void
    {
        $rider = User::query()->forceCreate([
            'name' => 'Rider',
            'phone' => '777200001',
            'type' => 'rider',
            'fcm_token' => null,
            'is_active' => true,
            'email' => '777200001@mashoar.local',
            'password' => bcrypt('x'),
        ]);

        $driver = User::query()->forceCreate([
            'name' => 'Driver',
            'phone' => '777200002',
            'type' => 'driver',
            'fcm_token' => null,
            'is_active' => true,
            'email' => '777200002@mashoar.local',
            'password' => bcrypt('x'),
        ]);

        DriverProfile::query()->create([
            'user_id' => $driver->id,
            'last_lat' => 15.3694,
            'last_lng' => 44.1910,
            'last_seen_at' => now(),
            'is_online' => true,
        ]);

        $this->assertSame('rider', $rider->fresh()->type);
        $this->assertSame('driver', $driver->fresh()->type);

        Sanctum::actingAs($rider);
        $tripRes = $this->postJson('/api/v1/trips/request', [
                'pickup_lat' => 15.3694,
                'pickup_lng' => 44.1910,
                'dropoff_lat' => 15.4,
                'dropoff_lng' => 44.2,
                'offered_price' => 10000,
            ])->assertOk()->json('trip');

        $this->assertNotNull($tripRes['id']);

        Sanctum::actingAs($driver);
        $bidResponse = $this->postJson('/api/v1/trips/'.$tripRes['id'].'/bid', [
                'amount' => 12000,
            ]);

        // If this fails, the response will show why via assertOk().

        $bid = $bidResponse->assertOk()->json('bid');

        Sanctum::actingAs($rider);
        $this->postJson('/api/v1/trips/'.$tripRes['id'].'/accept', [
                'bid_id' => $bid['id'],
            ])->assertOk()->assertJsonFragment(['message' => 'bid_accepted']);

        Sanctum::actingAs($driver);
        $complete = $this->postJson('/api/v1/trips/'.$tripRes['id'].'/complete', [])
            ->assertOk()
            ->json();

        $this->assertSame('trip_completed', $complete['message']);

        $trip = Trip::query()->findOrFail($tripRes['id']);
        $this->assertSame('completed', $trip->status);
        $this->assertGreaterThan(0, (float) $trip->commission_amount);

        $wallet = Wallet::query()->where('user_id', $driver->id)->first();
        $this->assertNotNull($wallet);
        $this->assertLessThan(0, (float) $wallet->balance);
    }

    public function test_debt_limit_blocks_accepting_bid(): void
    {
        $rider = User::query()->forceCreate([
            'name' => 'Rider2',
            'phone' => '777200011',
            'type' => 'rider',
            'fcm_token' => null,
            'is_active' => true,
            'email' => '777200011@mashoar.local',
            'password' => bcrypt('x'),
        ]);

        $driver = User::query()->forceCreate([
            'name' => 'Driver2',
            'phone' => '777200012',
            'type' => 'driver',
            'fcm_token' => null,
            'is_active' => true,
            'email' => '777200012@mashoar.local',
            'password' => bcrypt('x'),
        ]);

        Wallet::query()->create([
            'user_id' => $driver->id,
            'balance' => -6000,
            'debt_limit' => 5000,
        ]);

        Sanctum::actingAs($rider);
        $tripId = $this->postJson('/api/v1/trips/request', [
                'pickup_lat' => 15.3,
                'pickup_lng' => 44.1,
                'dropoff_lat' => 15.4,
                'dropoff_lng' => 44.2,
            ])->assertOk()->json('trip.id');

        Sanctum::actingAs($driver);
        $bidRes = $this->postJson('/api/v1/trips/'.$tripId.'/bid', ['amount' => 10000]);

        // If this fails, the response will show why via assertOk().

        $bidId = $bidRes->assertOk()->json('bid.id');

        Sanctum::actingAs($rider);
        $this->postJson('/api/v1/trips/'.$tripId.'/accept', ['bid_id' => $bidId])
            ->assertStatus(422)
            ->assertJsonFragment(['message' => 'debt_limit_exceeded']);
    }
}
