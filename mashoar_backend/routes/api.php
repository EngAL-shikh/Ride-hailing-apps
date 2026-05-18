<?php

use App\Http\Controllers\Api\V1\AuthController;
use App\Http\Controllers\Api\V1\DriverController;
use App\Http\Controllers\Api\V1\TripController;
use App\Http\Controllers\Api\V1\UiLayoutController;
use App\Http\Controllers\Api\V1\WalletController;
use App\Http\Controllers\Api\V1\SettingsController;
use App\Http\Controllers\Api\V1\PromoCodeController;
use Illuminate\Support\Facades\Route;

Route::prefix('v1')->group(function () {
    // Public endpoints
    Route::get('settings', [SettingsController::class, 'index']);
    Route::get('ui/layouts/{key}', [UiLayoutController::class, 'show']);
    Route::get('drivers/nearby', [DriverController::class, 'nearby']);
    
    Route::prefix('auth')->group(function () {
        Route::post('register', [AuthController::class, 'register']);
        Route::post('request-otp', [AuthController::class, 'requestOtp']);
        Route::post('verify-otp', [AuthController::class, 'verifyOtp']);
        Route::post('logout', [AuthController::class, 'logout'])->middleware('auth:sanctum');
    });

    Route::middleware('auth:sanctum')->group(function () {
        // Shared Endpoints
        Route::get('trips/my', [TripController::class, 'my']);
        Route::get('trips/driver/my', [TripController::class, 'my']); // Legacy
        Route::post('trips/request', [TripController::class, 'request']);
        Route::post('trips/{trip}/cancel', [TripController::class, 'cancel']);
        Route::post('trips/{trip}/review', [TripController::class, 'review']);
        
        Route::get('wallet/me', [WalletController::class, 'me']);
        
        // Push Notification Token Update
        Route::post('auth/update-fcm-token', [AuthController::class, 'updateFcmToken']);

        // Driver Specific Routes (Strictly Enforced)
        Route::middleware('driver.active')->group(function () {
            Route::post('driver/pulse', [DriverController::class, 'pulse']);
            Route::get('trips/available', [TripController::class, 'available']);
            Route::post('trips/{trip}/bid', [TripController::class, 'bid']);
            Route::post('trips/{trip}/arrival', [TripController::class, 'arrival']);
            Route::post('trips/{trip}/start', [TripController::class, 'start']);
            Route::post('trips/{trip}/complete', [TripController::class, 'complete']);
        });

        // Rider Specific Trip Actions
        Route::post('trips/{trip}/accept', [TripController::class, 'accept']);
        Route::get('trips/{trip}/bids', [TripController::class, 'bids']);

        // Promo codes
        Route::post('promo-codes/validate', [PromoCodeController::class, 'validate']);
        Route::post('promo-codes/apply', [PromoCodeController::class, 'apply']);
    });
});
