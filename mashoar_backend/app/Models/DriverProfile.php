<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasOne;
use Illuminate\Database\Eloquent\Relations\HasMany;


class DriverProfile extends Model
{
    protected $fillable = [
        'user_id',
        'full_name',
        'bike_plate',
        'id_card_front_path',
        'id_card_back_path',
        'avatar_path',
        'verification_status',
        'verification_notes',
        'rating',
        'trips_count',
        'last_lat',
        'last_lng',
        'last_seen_at',
        'is_online',
    ];

    protected $casts = [
        'rating' => 'float',
        'trips_count' => 'integer',
        'last_lat' => 'float',
        'last_lng' => 'float',
        'last_seen_at' => 'datetime',
        'is_online' => 'boolean',
    ];

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }
    
    public function wallet(): HasOne
    {
        return $this->hasOne(Wallet::class, 'user_id', 'user_id');
    }

    /**
     * Get trips where this driver was assigned
     */
    public function trips(): HasMany
    {
        return $this->hasMany(Trip::class, 'driver_id', 'user_id');
    }

    /**
     * Get completed trips count
     */
    public function getCompletedTripsCountAttribute(): int
    {
        return $this->trips()->where('status', 'completed')->count();
    }

    /**
     * Get total earnings
     */
    public function getTotalEarningsAttribute(): float
    {
        return $this->trips()
            ->where('status', 'completed')
            ->selectRaw('SUM(accepted_price - commission_amount) as total')
            ->value('total') ?? 0;
    }
}

