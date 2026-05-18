<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::create('driver_profiles', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->unique()->constrained('users')->cascadeOnDelete();
            // Store coordinates as decimals for MySQL 8 compatibility without spatial Blueprint macros.
            // Spatial queries will use ST_Distance_Sphere(POINT(last_lng,last_lat), POINT(:lng,:lat)).
            $table->decimal('last_lat', 10, 7)->nullable()->index();
            $table->decimal('last_lng', 10, 7)->nullable()->index();
            $table->timestamp('last_seen_at')->nullable()->index();
            $table->boolean('is_online')->default(false)->index();
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('driver_profiles');
    }
};
