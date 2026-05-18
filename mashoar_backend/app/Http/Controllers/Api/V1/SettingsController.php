<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\SystemSetting;
use Illuminate\Support\Facades\Cache;

class SettingsController extends Controller
{
    /**
     * Get all app settings for mobile app
     * Cached for 1 hour to reduce database load
     */
    public function index()
    {
        $settings = Cache::remember('app_settings', 3600, function () {
            return SystemSetting::all()->groupBy('group');
        });

        return response()->json([
            'app' => $this->getGroupSettings($settings, 'app'),
            'pricing' => $this->getGroupSettings($settings, 'pricing'),
            'driver' => $this->getGroupSettings($settings, 'driver'),
            'rider' => $this->getGroupSettings($settings, 'rider'),
            'payment' => $this->getGroupSettings($settings, 'payment'),
            'maps' => $this->getGroupSettings($settings, 'maps'),
            'features' => $this->getGroupSettings($settings, 'features'),
            'notifications' => $this->getGroupSettings($settings, 'notifications'),
        ]);
    }

    /**
     * Get settings for a specific group
     */
    private function getGroupSettings($settings, $group)
    {
        $groupSettings = $settings->get($group, collect());
        
        $result = [];
        foreach ($groupSettings as $setting) {
            $result[$setting->key] = $this->castValue($setting->value, $setting->type);
        }
        
        return $result;
    }

    /**
     * Cast setting value to appropriate type
     */
    private function castValue($value, $type)
    {
        switch ($type) {
            case 'boolean':
                return filter_var($value, FILTER_VALIDATE_BOOLEAN);
            case 'integer':
                return (int) $value;
            case 'float':
                return (float) $value;
            case 'json':
                return json_decode($value, true);
            default:
                return $value;
        }
    }
}
