<?php

namespace App\Services;

use App\Models\UiLayout;
use Illuminate\Support\Facades\Cache;

class LayoutService
{
    public function getLayout(string $key, string $platform = 'mobile', ?string $locale = null): UiLayout
    {
        $locale = $locale ?: config('app.locale', 'ar');

        $cacheKey = sprintf('ui_layout:%s:%s:%s', $platform, $locale, $key);

        return Cache::remember($cacheKey, 300, function () use ($key, $platform, $locale) {
            $layout = UiLayout::query()
                ->where('key', $key)
                ->where('platform', $platform)
                ->where('is_active', true)
                ->where(function ($q) use ($locale) {
                    $q->whereNull('locale')->orWhere('locale', $locale);
                })
                ->orderByRaw('locale is null') // prefer exact locale over null
                ->first();

            if (! $layout) {
                abort(404, 'layout_not_found');
            }

            return $layout;
        });
    }
}
