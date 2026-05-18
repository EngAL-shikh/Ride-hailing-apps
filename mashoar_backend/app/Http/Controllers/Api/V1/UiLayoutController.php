<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\UiLayout;
use Illuminate\Support\Facades\Cache;

class UiLayoutController extends Controller
{
    /**
     * Get SDUI layout by key
     * Used by mobile app to render dynamic screens
     */
    public function show($key)
    {
        $platform = request('platform', 'mobile');
        $locale = request('locale', 'ar');
        
        $cacheKey = "ui_layout_{$key}_{$platform}_{$locale}";
        
        $layout = Cache::remember($cacheKey, 3600, function () use ($key, $platform, $locale) {
            return UiLayout::where('key', $key)
                ->where('platform', $platform)
                ->where('locale', $locale)
                ->where('is_active', true)
                ->first() ?? UiLayout::where('key', $key)->first(); // Fallback to first if no specific match
        });

        if (!$layout || !$layout->payload) {
            return response()->json([
                'data' => [
                    'key' => $key,
                    'payload' => [
                        'type' => 'column',
                        'children' => [],
                    ],
                    'message' => 'Layout not found, using default empty layout',
                ],
            ]);
        }

        // Return format expected by mobile app
        return response()->json([
            'data' => [
                'key' => $layout->key,
                'payload' => $layout->payload, // This is the full SDUI structure
                'updated_at' => $layout->updated_at->toIso8601String(),
            ],
        ]);
    }
}
