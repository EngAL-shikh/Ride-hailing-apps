<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Resources\WalletResource;
use App\Services\WalletService;
use Illuminate\Http\JsonResponse;

class WalletController extends Controller
{
    public function me(WalletService $wallets): JsonResponse
    {
        $user = request()->user();
        if (! $user || $user->type !== 'driver') {
            return response()->json(['message' => 'forbidden'], 403);
        }

        $wallet = $wallets->ensureWallet($user);

        return response()->json([
            'data' => new WalletResource($wallet),
        ]);
    }
}
