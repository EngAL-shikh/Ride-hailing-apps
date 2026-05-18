<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;

class PromoCode extends Model
{
    protected $fillable = [
        'code',
        'type',
        'value',
        'min_trip_amount',
        'max_discount',
        'usage_limit_total',
        'usage_limit_per_user',
        'used_count',
        'new_users_only',
        'valid_from',
        'valid_until',
        'is_active',
        'description',
    ];

    protected $casts = [
        'value' => 'float',
        'min_trip_amount' => 'float',
        'max_discount' => 'float',
        'usage_limit_total' => 'integer',
        'usage_limit_per_user' => 'integer',
        'used_count' => 'integer',
        'new_users_only' => 'boolean',
        'valid_from' => 'datetime',
        'valid_until' => 'datetime',
        'is_active' => 'boolean',
    ];

    public function usages(): HasMany
    {
        return $this->hasMany(PromoCodeUsage::class);
    }

    public function isValid(): bool
    {
        if (!$this->is_active) {
            return false;
        }

        $now = now();

        if ($this->valid_from && $now->lt($this->valid_from)) {
            return false;
        }

        if ($this->valid_until && $now->gt($this->valid_until)) {
            return false;
        }

        if ($this->usage_limit_total && $this->used_count >= $this->usage_limit_total) {
            return false;
        }

        return true;
    }

    public function canBeUsedBy(User $user): bool
    {
        if (!$this->isValid()) {
            return false;
        }

        if ($this->new_users_only && $user->trips()->count() > 0) {
            return false;
        }

        $userUsageCount = $this->usages()->where('user_id', $user->id)->count();
        
        if ($userUsageCount >= $this->usage_limit_per_user) {
            return false;
        }

        return true;
    }

    public function calculateDiscount(float $tripAmount): float
    {
        if ($tripAmount < $this->min_trip_amount) {
            return 0;
        }

        return match($this->type) {
            'percentage' => min(
                $tripAmount * ($this->value / 100),
                $this->max_discount ?? PHP_FLOAT_MAX
            ),
            'fixed' => min($this->value, $tripAmount),
            'free_ride' => $tripAmount,
            default => 0,
        };
    }
}
