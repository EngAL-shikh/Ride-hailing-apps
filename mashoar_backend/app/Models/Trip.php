<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;


class Trip extends Model
{
    protected $fillable = [
        'rider_id',
        'driver_id',
        'pickup_lat',
        'pickup_lng',
        'dropoff_lat',
        'dropoff_lng',
        'offered_price',
        'accepted_price',
        'status',
        'commission_rate',
        'commission_amount',
        'accepted_at',
        'completed_at',
    ];

    protected $casts = [
        'pickup_lat' => 'float',
        'pickup_lng' => 'float',
        'dropoff_lat' => 'float',
        'dropoff_lng' => 'float',
        'offered_price' => 'float',
        'accepted_price' => 'float',
        'commission_rate' => 'float',
        'commission_amount' => 'float',
        'accepted_at' => 'datetime',
        'completed_at' => 'datetime',
    ];

    public function rider(): BelongsTo
    {
        return $this->belongsTo(User::class, 'rider_id');
    }

    public function driver(): BelongsTo
    {
        // Note: driver_id references driver_profiles.id, not users.id
        return $this->belongsTo(DriverProfile::class, 'driver_id');
    }
    
    // Helper to get driver's user info
    public function driverUser(): BelongsTo
    {
        return $this->hasOneThrough(User::class, DriverProfile::class, 'id', 'id', 'driver_id', 'user_id');
    }

    public function bids(): HasMany
    {
        return $this->hasMany(TripBid::class);
    }
}
