<?php

namespace App\Services;

use App\Models\SystemSetting;
use Illuminate\Support\Facades\Cache;

class SettingsService
{
    /**
     * Get a setting value with caching
     */
    public function get(string $key, $default = null)
    {
        return Cache::remember("setting:{$key}", 3600, function() use ($key, $default) {
            $setting = SystemSetting::where('key', $key)->first();
            return $setting ? $setting->getTypedValue() : $default;
        });
    }

    /**
     * Set a setting value
     */
    public function set(string $key, $value, string $type = 'string', string $group = null): void
    {
        SystemSetting::updateOrCreate(
            ['key' => $key],
            [
                'value' => $value,
                'type' => $type,
                'group' => $group,
            ]
        );

        Cache::forget("setting:{$key}");
    }

    /**
     * Get all settings in a group
     */
    public function getGroup(string $group): array
    {
        return Cache::remember("settings_group:{$group}", 3600, function() use ($group) {
            return SystemSetting::where('group', $group)
                ->get()
                ->mapWithKeys(fn($setting) => [$setting->key => $setting->getTypedValue()])
                ->toArray();
        });
    }

    /**
     * Clear all settings cache
     */
    public function clearCache(): void
    {
        Cache::flush();
    }
}
