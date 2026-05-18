<?php

namespace App\Services;

use App\Models\Trip;
use App\Models\User;
use App\Models\Wallet;
use App\Models\WalletTransaction;
use Illuminate\Support\Facades\DB;

class WalletService
{
    public function ensureWallet(User $user): Wallet
    {
        return Wallet::query()->firstOrCreate(
            ['user_id' => $user->id],
            [
                'balance' => 0,
                'debt_limit' => (float) config('mashoar.trip.default_debt_limit', 5000),
            ]
        );
    }

    public function canTakeMoreDebt(User $user, float $projectedDelta): bool
    {
        $wallet = $this->ensureWallet($user);
        $projectedBalance = (float) $wallet->balance + $projectedDelta;

        return $projectedBalance >= -1 * (float) $wallet->debt_limit;
    }

    /**
     * Apply commission as a debt entry (negative amount).
     */
    public function applyCommission(User $driver, Trip $trip, float $commissionAmount): Wallet
    {
        $wallet = $this->ensureWallet($driver);

        return DB::transaction(function () use ($wallet, $trip, $commissionAmount) {
            $wallet->refresh();
            $wallet->balance = (float) $wallet->balance - $commissionAmount;
            $wallet->save();

            WalletTransaction::query()->create([
                'wallet_id' => $wallet->id,
                'trip_id' => $trip->id,
                'type' => 'commission',
                'amount' => -1 * $commissionAmount,
                'meta' => [
                    'commission_rate' => (float) $trip->commission_rate,
                ],
            ]);

            return $wallet;
        });
    }
}

