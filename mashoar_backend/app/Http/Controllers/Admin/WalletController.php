<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\DriverProfile;
use App\Models\Wallet;
use App\Services\WalletService;
use Illuminate\Http\Request;

class WalletController extends Controller
{
    public function __construct(
        private WalletService $wallets
    ) {}

    public function index()
    {
        // Get all driver profiles with their wallets
        $drivers = DriverProfile::with(['user', 'wallet'])
            ->whereHas('wallet')
            ->get()
            ->map(function($driver) {
                $balance = $driver->wallet->transactions()->sum('amount');
                $driver->wallet_balance = $balance;
                return $driver;
            })
            ->sortByDesc('wallet_balance')
            ->take(20);

        return view('admin.wallets.index', compact('drivers'));
    }

    public function transaction(Request $request)
    {
        $validated = $request->validate([
            'driver_phone' => 'required|string',
            'amount' => 'required|numeric|min:0.01',
            'type' => 'required|in:credit,debit',
            'note' => 'required|string|max:500',
        ]);

        // Find driver by phone
        $driver = DriverProfile::whereHas('user', function($q) use ($validated) {
            $q->where('phone', $validated['driver_phone']);
        })->firstOrFail();

        // Calculate amount (debit = negative)
        $amount = $validated['type'] === 'debit' 
            ? -abs($validated['amount']) 
            : abs($validated['amount']);

        // Add transaction
        $this->wallets->addTransaction($driver, $amount, 'manual_adjustment', [
            'note' => $validated['note'],
            'admin_id' => auth()->id() ?? 1,
        ]);

        return back()->with('success', 'تم تنفيذ العملية بنجاح');
    }
}
