<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\Relations\HasOne;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Laravel\Sanctum\HasApiTokens;

class User extends Authenticatable
{
    use HasApiTokens, HasFactory, Notifiable;

    /**
     * The attributes that are mass assignable.
     *
     * @var array<int, string>
     */
    protected $fillable = [
        'name',
        'email',
        'password',
        'phone',
        'type',
        'fcm_token',
        'is_active',
    ];

    /**
     * The attributes that should be hidden for serialization.
     *
     * @var array<int, string>
     */
    protected $hidden = [
        'password',
        'remember_token',
        'fcm_token',
    ];

    /**
     * Get the attributes that should be cast.
     *
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'is_active' => 'boolean',
            'email_verified_at' => 'datetime',
        ];
    }

    /**
     * Get the driver profile for the user.
     */
    public function driverProfile(): HasOne
    {
        return $this->hasOne(DriverProfile::class);
    }

    /**
     * Get all trips for the user (as rider or driver).
     */
    public function trips(): HasMany
    {
        return $this->hasMany(Trip::class, 'rider_id');
    }

    /**
     * Get trips where user is the driver.
     */
    public function driverTrips(): HasMany
    {
        return $this->hasMany(Trip::class, 'driver_id');
    }

    /**
     * Get the wallet for the user.
     */
    public function wallet(): HasOne
    {
        return $this->hasOne(Wallet::class);
    }

    /**
     * Check if user is a driver.
     */
    public function isDriver(): bool
    {
        return $this->type === 'driver';
    }

    /**
     * Check if user is a rider.
     */
    public function isRider(): bool
    {
        return $this->type === 'rider';
    }
}
