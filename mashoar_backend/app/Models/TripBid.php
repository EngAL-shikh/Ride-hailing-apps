<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class TripBid extends Model
{
    protected $fillable = [
        'trip_id',
        'driver_id',
        'amount',
        'status',
    ];

    protected $casts = [
        'amount' => 'float',
    ];

    public function trip(): BelongsTo
    {
        return $this->belongsTo(Trip::class);
    }

    public function driver(): BelongsTo
    {
        return $this->belongsTo(User::class, 'driver_id');
    }
}
