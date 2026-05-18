<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Admin\DashboardController;
use App\Http\Controllers\Admin\SettingsController;
use App\Http\Controllers\Admin\DriverController;
use App\Http\Controllers\Admin\UserController;
use App\Http\Controllers\Admin\WalletController;
use App\Http\Controllers\Admin\MarketingController;
use App\Http\Controllers\Admin\SduiController;
use App\Http\Controllers\Admin\PromoCodeController;
use App\Http\Controllers\Admin\TripController;
use App\Http\Controllers\Admin\SupportController;
use App\Http\Controllers\Admin\FirebaseController;

Route::get('/version-check', function() {
    return 'DEPLOYMENT_ACTIVE_V102_FIXED_FCM_' . time();
});

Route::get('/', function () {
    return view('welcome');
});

// ⚡ Emergency Design Sync (Local to Production Mirror)
// Accessible at http://your-domain.com/sync-design
Route::get('/sync-design', function() {
    try {
        // 1. Clear old data
        \Illuminate\Support\Facades\DB::table('ui_layouts')->where('key', 'home')->delete();
        
        // 2. Local v29 Payload
        $payload = json_decode('{"type":"column","children":[{"type":"spacer","props":{"height":352}},{"type":"padding","props":{"left":16,"right":16,"bottom":32},"children":[{"type":"container","props":{"padding":{"all":20},"borderRadius":32,"color":"#1f2f50","border":true,"borderColor":"#374151","borderWidth":1.5,"boxShadow":[{"color":"#00000066","blurRadius":25,"offsetY":12}]},"children":[{"type":"profileHeader","props":[]}]}]},{"type":"padding","props":{"left":16,"right":16,"bottom":24},"children":[{"type":"container","props":{"borderRadius":28,"clipBehavior":"antiAlias","gradient":{"colors":["#10B981","#059669"],"begin":"topLeft","end":"bottomRight"},"boxShadow":[{"color":"#10B98144","blurRadius":20,"offsetY":8}],"action":"route:\/ride-map"},"children":[{"type":"padding","props":{"all":24},"children":[{"type":"row","children":[{"type":"column","props":{"crossAxisAlignment":"start","flex":1},"children":[{"type":"text","props":{"value":"\u0627\u0637\u0644\u0628 \u0639\u0628\u0631 \u0627\u0644\u062e\u0631\u064a\u0637\u0629","style":{"fontSize":22,"fontWeight":"bold","color":"#FFFFFF"}}},{"type":"text","props":{"value":"\u062d\u062f\u062f \u0648\u062c\u0647\u062a\u0643 \u0628\u062f\u0642\u0629 \u0645\u062a\u0646\u0627\u0647\u064a\u0629","style":{"fontSize":14,"color":"#ECFDF5"}}}]},{"type":"icon","props":{"icon":"map","color":"#FFFFFF","size":40}}]}]}]}]},{"type":"padding","props":{"left":16,"right":16,"bottom":32},"children":[{"type":"row","props":{"mainAxisAlignment":"spaceBetween"},"children":[{"type":"flexible","props":{"flex":1},"children":[{"type":"container","props":{"height":100,"borderRadius":24,"color":"#4F46E5","action":"route:\/ride-request"},"children":[{"type":"column","props":{"mainAxisAlignment":"center"},"children":[{"type":"icon","props":{"icon":"ride","color":"#FFFFFF","size":24}},{"type":"spacer","props":{"height":8}},{"type":"text","props":{"value":"\u0637\u0644\u0628 \u0633\u0631\u064ي\u0639","style":{"fontSize":13,"color":"#FFFFFF","fontWeight":"w600"}}}]}]}]},{"type":"spacer","props":{"width":12}},{"type":"flexible","props":{"flex":1},"children":[{"type":"container","props":{"height":100,"borderRadius":24,"color":"#1F2937","action":"route:\/my-trips"},"children":[{"type":"column","props":{"mainAxisAlignment":"center"},"children":[{"type":"icon","props":{"icon":"history","color":"#10B981","size":24}},{"type":"spacer","props":{"height":8}},{"type":"text","props":{"value":"\u0631\u062d\u0644\u0627\u062a\u064ي","style":{"fontSize":13,"color":"#FFFFFF","fontWeight":"w600"}}}]}]}]},{"type":"spacer","props":{"width":12}},{"type":"flexible","props":{"flex":1},"children":[{"type":"container","props":{"height":100,"borderRadius":24,"color":"#1F2937","action":"route:\/wallet"},"children":[{"type":"column","props":{"mainAxisAlignment":"center"},"children":[{"type":"icon","props":{"icon":"wallet","color":"#A78BFA","size":24}},{"type":"spacer","props":{"height":8}},{"type":"text","props":{"value":"\u0627\u0644\u0645\u062d\u0641\u0638\u0629","style":{"fontSize":13,"color":"#FFFFFF","fontWeight":"w600"}}}]}]}]}]}]},{"type":"padding","props":{"left":16,"right":16,"bottom":16},"children":[{"type":"text","props":{"value":"\u0643\u0628\u0627\u062a\u0646 \u0628\u0627\u0644\u0642\u0631\u0628 \u0645\u0646\u0643","style":{"fontSize":18,"fontWeight":"bold","color":"#FFFFFF"}}}]},{"type":"driversList","props":[]},{"type":"spacer","props":{"height":40}}]}', true);

        \App\Models\UiLayout::insert([
            'key' => 'home',
            'platform' => 'mobile',
            'locale' => 'ar',
            'payload' => json_encode($payload, JSON_UNESCAPED_UNICODE),
            'version' => 29,
            'is_active' => true,
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        // 3. Force Clear Cache
        \Illuminate\Support\Facades\Artisan::call('cache:clear');
        \Illuminate\Support\Facades\Artisan::call('route:clear');
        
        return "✅ SUCCESS: Production design synchronized with Local v29. Cache flushed.";
    } catch (\Exception $e) {
        return "❌ ERROR: " . $e->getMessage();
    }
});

// Admin Routes (Isolated from API)
Route::prefix('admin')->name('admin.')->middleware(['web'])->group(function () {
    Route::get('/', [DashboardController::class, 'index'])->name('dashboard');
    Route::post('/sync-design', [DashboardController::class, 'syncDesign'])->name('sync-design');
    
    // Settings
    Route::get('/settings', [SettingsController::class, 'index'])->name('settings.index');
    Route::put('/settings', [SettingsController::class, 'update'])->name('settings.update');
    
    // Drivers
    Route::get('drivers/{driver}/trips', [DriverController::class, 'trips'])->name('drivers.trips');
    Route::resource('drivers', DriverController::class);
    Route::post('drivers/{driver}/verify', [DriverController::class, 'verify'])->name('drivers.verify');
    Route::post('drivers/{driver}/toggle-status', [DriverController::class, 'toggleStatus'])->name('drivers.toggle-status');

    
    // Users
    Route::resource('users', UserController::class);
    
    // Wallets
    Route::get('/wallets', [WalletController::class, 'index'])->name('wallets.index');
    Route::post('/wallets/transaction', [WalletController::class, 'transaction'])->name('wallets.transaction');
    
    // Marketing
    Route::get('/marketing', [MarketingController::class, 'index'])->name('marketing.index');
    Route::post('/marketing/send', [MarketingController::class, 'send'])->name('marketing.send');
    
    // SDUI Builder
    Route::get('/sdui', [SduiController::class, 'index'])->name('sdui.index');
    Route::post('/sdui', [SduiController::class, 'store'])->name('sdui.store');
    Route::put('/sdui', [SduiController::class, 'update'])->name('sdui.update');
    Route::post('/sdui/add-widget', [SduiController::class, 'addWidget'])->name('sdui.add-widget');
    Route::get('/sdui/delete-widget/{index}', [SduiController::class, 'deleteWidget'])->name('sdui.delete-widget');
    
    // Promo Codes
    Route::resource('promo-codes', PromoCodeController::class);
    Route::post('promo-codes/{promoCode}/toggle', [PromoCodeController::class, 'toggle'])->name('promo-codes.toggle');
    
    // Trips
    Route::get('/trips', [TripController::class, 'index'])->name('trips.index');
    Route::get('/trips/{trip}', [TripController::class, 'show'])->name('trips.show');
    
    // Support Tickets
    Route::get('/support', [SupportController::class, 'index'])->name('support.index');
    Route::get('/support/{ticket}', [SupportController::class, 'show'])->name('support.show');
    Route::post('/support/{ticket}/status', [SupportController::class, 'updateStatus'])->name('support.update-status');
    Route::post('/support/{ticket}/reply', [SupportController::class, 'reply'])->name('support.reply');
    
    // Firebase
    Route::get('/firebase', [FirebaseController::class, 'index'])->name('firebase.index');
    Route::post('/firebase/test', [FirebaseController::class, 'testNotification'])->name('firebase.test');
    
    // Debug Layout
    Route::get('/debug-layout', function() {
        return response()->json(App\Models\UiLayout::where('key', 'home')->get());
    })->name('debug-layout');

    // Emergency Design Sync (Local to Production Mirror)
    Route::get('/sync-design', function() {
        try {
            // 1. Clear old data
            \App\Models\UiLayout::where('key', 'home')->delete();
            
            // 2. Local v29 Payload
            $payload = json_decode('{"type":"column","children":[{"type":"spacer","props":{"height":352}},{"type":"padding","props":{"left":16,"right":16,"bottom":32},"children":[{"type":"container","props":{"padding":{"all":20},"borderRadius":32,"color":"#1f2f50","border":true,"borderColor":"#374151","borderWidth":1.5,"boxShadow":[{"color":"#00000066","blurRadius":25,"offsetY":12}]},"children":[{"type":"profileHeader","props":[]}]}]},{"type":"padding","props":{"left":16,"right":16,"bottom":24},"children":[{"type":"container","props":{"borderRadius":28,"clipBehavior":"antiAlias","gradient":{"colors":["#10B981","#059669"],"begin":"topLeft","end":"bottomRight"},"boxShadow":[{"color":"#10B98144","blurRadius":20,"offsetY":8}],"action":"route:\/ride-map"},"children":[{"type":"padding","props":{"all":24},"children":[{"type":"row","children":[{"type":"column","props":{"crossAxisAlignment":"start","flex":1},"children":[{"type":"text","props":{"value":"\u0627\u0637\u0644\u0628 \u0639\u0628\u0631 \u0627\u0644\u062e\u0631\u064a\u0637\u0629","style":{"fontSize":22,"fontWeight":"bold","color":"#FFFFFF"}}},{"type":"text","props":{"value":"\u062d\u062f\u062f \u0648\u062c\u0647\u062a\u0643 \u0628\u062f\u0642\u0629 \u0645\u062a\u0646\u0627\u0647\u064a\u0629","style":{"fontSize":14,"color":"#ECFDF5"}}}]},{"type":"icon","props":{"icon":"map","color":"#FFFFFF","size":40}}]}]}]}]},{"type":"padding","props":{"left":16,"right":16,"bottom":32},"children":[{"type":"row","props":{"mainAxisAlignment":"spaceBetween"},"children":[{"type":"flexible","props":{"flex":1},"children":[{"type":"container","props":{"height":100,"borderRadius":24,"color":"#4F46E5","action":"route:\/ride-request"},"children":[{"type":"column","props":{"mainAxisAlignment":"center"},"children":[{"type":"icon","props":{"icon":"ride","color":"#FFFFFF","size":24}},{"type":"spacer","props":{"height":8}},{"type":"text","props":{"value":"\u0637\u0644\u0628 \u0633\u0631\u064a\u0639","style":{"fontSize":13,"color":"#FFFFFF","fontWeight":"w600"}}}]}]}]},{"type":"spacer","props":{"width":12}},{"type":"flexible","props":{"flex":1},"children":[{"type":"container","props":{"height":100,"borderRadius":24,"color":"#1F2937","action":"route:\/my-trips"},"children":[{"type":"column","props":{"mainAxisAlignment":"center"},"children":[{"type":"icon","props":{"icon":"history","color":"#10B981","size":24}},{"type":"spacer","props":{"height":8}},{"type":"text","props":{"value":"\u0631\u062d\u0644\u0627\u062a\u064ي","style":{"fontSize":13,"color":"#FFFFFF","fontWeight":"w600"}}}]}]}]},{"type":"spacer","props":{"width":12}},{"type":"flexible","props":{"flex":1},"children":[{"type":"container","props":{"height":100,"borderRadius":24,"color":"#1F2937","action":"route:\/wallet"},"children":[{"type":"column","props":{"mainAxisAlignment":"center"},"children":[{"type":"icon","props":{"icon":"wallet","color":"#A78BFA","size":24}},{"type":"spacer","props":{"height":8}},{"type":"text","props":{"value":"\u0627\u0644\u0645\u062d\u0641\u0638\u0629","style":{"fontSize":13,"color":"#FFFFFF","fontWeight":"w600"}}}]}]}]}]}]},{"type":"padding","props":{"left":16,"right":16,"bottom":16},"children":[{"type":"text","props":{"value":"\u0643\u0628\u0627\u062a\u0646 \u0628\u0627\u0644\u0642\u0631\u0628 \u0645\u0646\u0643","style":{"fontSize":18,"fontWeight":"bold","color":"#FFFFFF"}}}]},{"type":"driversList","props":[]},{"type":"spacer","props":{"height":40}}]}', true);

            \App\Models\UiLayout::create([
                'key' => 'home',
                'platform' => 'mobile',
                'locale' => 'ar',
                'payload' => $payload,
                'version' => 29,
                'is_active' => true,
            ]);

            // 3. Clear Cache
            \Illuminate\Support\Facades\Cache::flush();
            \Illuminate\Support\Facades\Artisan::call('cache:clear');
            
            return "✅ SUCCESS: Production design is now a mirror of LOCAL v29. Cache cleared.";
        } catch (\Exception $e) {
            return "❌ ERROR: " . $e->getMessage();
        }
    })->name('sync-design');
});
