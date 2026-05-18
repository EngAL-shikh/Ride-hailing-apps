<?php

namespace Tests\Feature;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Cache;
use Tests\TestCase;

class DriverPulseTest extends TestCase
{
    use RefreshDatabase;

    public function test_driver_can_pulse_location_with_sanctum_token(): void
    {
        // Register driver
        $this->postJson('/api/v1/auth/register', [
            'name' => 'Driver One',
            'phone' => '777000111',
            'type' => 'driver',
        ])->assertOk();

        // Request OTP (debug OTP is returned when app.debug=true)
        $otpResp = $this->postJson('/api/v1/auth/request-otp', [
            'phone' => '777000111',
        ])->assertOk()->json();

        $this->assertArrayHasKey('otp_debug', $otpResp);

        // Verify OTP -> token
        $verifyResp = $this->postJson('/api/v1/auth/verify-otp', [
            'phone' => '777000111',
            'otp' => $otpResp['otp_debug'],
            'device_name' => 'test',
        ])->assertOk()->json();

        $this->assertArrayHasKey('token', $verifyResp);

        // Pulse
        $this->withHeader('Authorization', 'Bearer '.$verifyResp['token'])
            ->postJson('/api/v1/driver/pulse', [
                'lat' => 15.3694,
                'lng' => 44.1910,
                'is_online' => true,
            ])
            ->assertOk()
            ->assertJsonFragment(['message' => 'pulse_ok']);

        $driver = User::where('phone', '777000111')->firstOrFail();

        $this->assertNotNull($driver->driverProfile);
        $this->assertEquals(15.3694, (float) $driver->driverProfile->last_lat);
        $this->assertEquals(44.1910, (float) $driver->driverProfile->last_lng);
        $this->assertTrue((bool) $driver->driverProfile->is_online);
    }

    public function test_rider_cannot_pulse(): void
    {
        $rider = User::create([
            'name' => 'Rider One',
            'phone' => '777000222',
            'type' => 'rider',
            'fcm_token' => null,
            'is_active' => true,
            'email' => '777000222@mashoar.local',
            'password' => bcrypt('x'),
        ]);

        $token = $rider->createToken('test')->plainTextToken;

        $this->withHeader('Authorization', 'Bearer '.$token)
            ->postJson('/api/v1/driver/pulse', [
                'lat' => 15.0,
                'lng' => 44.0,
            ])->assertStatus(403);
    }
}

