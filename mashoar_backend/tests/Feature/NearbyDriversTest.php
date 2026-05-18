<?php

namespace Tests\Feature;

use App\Models\DriverProfile;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class NearbyDriversTest extends TestCase
{
    use RefreshDatabase;

    public function test_returns_nearby_online_drivers_sorted_by_distance(): void
    {
        $near = User::query()->forceCreate([
            'name' => 'Near Driver',
            'phone' => '777100001',
            'type' => 'driver',
            'fcm_token' => null,
            'is_active' => true,
            'email' => '777100001@mashoar.local',
            'password' => bcrypt('x'),
        ]);

        $far = User::query()->forceCreate([
            'name' => 'Far Driver',
            'phone' => '777100002',
            'type' => 'driver',
            'fcm_token' => null,
            'is_active' => true,
            'email' => '777100002@mashoar.local',
            'password' => bcrypt('x'),
        ]);

        DriverProfile::query()->create([
            'user_id' => $near->id,
            'last_lat' => 15.3700,
            'last_lng' => 44.1910,
            'last_seen_at' => now(),
            'is_online' => true,
        ]);

        DriverProfile::query()->create([
            'user_id' => $far->id,
            'last_lat' => 15.5000,
            'last_lng' => 44.5000,
            'last_seen_at' => now(),
            'is_online' => true,
        ]);

        $res = $this->getJson('/api/v1/drivers/nearby?lat=15.3694&lng=44.1910&radius_km=50&limit=10')
            ->assertOk()
            ->json('data');

        $this->assertNotEmpty($res);
        $this->assertSame($near->id, $res[0]['id']);
    }
}
