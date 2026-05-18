<?php

namespace Tests\Feature;

use App\Models\Trip;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class TripBidsListTest extends TestCase
{
    use RefreshDatabase;

    public function test_rider_can_list_trip_bids(): void
    {
        $rider = User::query()->forceCreate([
            'name' => 'Rider',
            'phone' => '777300001',
            'type' => 'rider',
            'fcm_token' => null,
            'is_active' => true,
            'email' => '777300001@mashoar.local',
            'password' => bcrypt('x'),
        ]);

        $driver = User::query()->forceCreate([
            'name' => 'Driver',
            'phone' => '777300002',
            'type' => 'driver',
            'fcm_token' => null,
            'is_active' => true,
            'email' => '777300002@mashoar.local',
            'password' => bcrypt('x'),
        ]);

        $trip = Trip::query()->create([
            'rider_id' => $rider->id,
            'pickup_lat' => 15.3,
            'pickup_lng' => 44.1,
            'dropoff_lat' => 15.4,
            'dropoff_lng' => 44.2,
            'status' => 'bidding',
            'commission_rate' => 0.15,
            'commission_amount' => 0,
        ]);

        $trip->bids()->create([
            'driver_id' => $driver->id,
            'amount' => 12000,
            'status' => 'pending',
        ]);

        Sanctum::actingAs($rider);

        $this->getJson('/api/v1/trips/'.$trip->id.'/bids')
            ->assertOk()
            ->assertJsonCount(1, 'data')
            ->assertJsonFragment(['driver_id' => $driver->id]);
    }
}
