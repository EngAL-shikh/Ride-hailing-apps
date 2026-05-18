<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('system_settings', function (Blueprint $table) {
            $table->id();
            $table->string('key')->unique();
            $table->text('value')->nullable();
            $table->enum('type', ['string', 'number', 'boolean', 'json'])->default('string');
            $table->string('group', 100)->nullable()->index();
            $table->text('description')->nullable();
            $table->timestamps();
        });

        // Insert default settings
        DB::table('system_settings')->insert([
            [
                'key' => 'search_radius_km',
                'value' => '10',
                'type' => 'number',
                'group' => 'general',
                'description' => 'Default search radius for nearby drivers (km)',
                'created_at' => now(),
                'updated_at' => now(),
            ],
            [
                'key' => 'commission_rate',
                'value' => '0.15',
                'type' => 'number',
                'group' => 'general',
                'description' => 'Commission rate (0-1, e.g., 0.15 = 15%)',
                'created_at' => now(),
                'updated_at' => now(),
            ],
            [
                'key' => 'driver_pulse_interval_seconds',
                'value' => '30',
                'type' => 'number',
                'group' => 'general',
                'description' => 'Driver location update interval (seconds)',
                'created_at' => now(),
                'updated_at' => now(),
            ],
            [
                'key' => 'min_trip_price',
                'value' => '500',
                'type' => 'number',
                'group' => 'general',
                'description' => 'Minimum trip price (YER)',
                'created_at' => now(),
                'updated_at' => now(),
            ],
        ]);
    }

    public function down(): void
    {
        Schema::dropIfExists('system_settings');
    }
};
