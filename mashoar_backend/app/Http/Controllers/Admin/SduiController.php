<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\UiLayout;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Cache;

class SduiController extends Controller
{
    public function index(Request $request)
    {
        $platform = $request->get('platform', 'mobile');
        $locale = $request->get('locale', 'ar');

        // Load specific layout or fallback
        $activeLayout = UiLayout::where('key', 'home')
            ->where('platform', $platform)
            ->where('locale', $locale)
            ->where('is_active', true)
            ->first() ?? UiLayout::where('key', 'home')->first();
        
        // Debug logging
        \Log::info('SDUI Controller - Layout loaded', [
            'platform' => $platform,
            'locale' => $locale,
            'layout_exists' => $activeLayout ? 'YES' : 'NO',
            'layout_id' => $activeLayout->id ?? 'N/A',
        ]);
        
        // If no layout exists, create specific one
        if (!$activeLayout) {
            $activeLayout = UiLayout::create([
                'key' => 'home',
                'platform' => $platform,
                'locale' => $locale,
                'payload' => [
                    'type' => 'column',
                    'children' => [],
                ],
                'is_active' => true,
            ]);
        }
        
        $widgets = $activeLayout->payload['children'] ?? [];
        $backgroundImage = $activeLayout->payload['background_image'] ?? null;
        
        return view('admin.sdui.index', compact('widgets', 'activeLayout', 'backgroundImage', 'platform', 'locale'));
    }


    public function store(Request $request)
    {
        $validated = $request->validate([
            'key' => 'required|string',
            'widgets' => 'required|array',
            'background_image' => 'nullable|string',
            'platform' => 'nullable|string',
            'locale' => 'nullable|string',
        ]);

        $platform = $validated['platform'] ?? 'mobile';
        $locale = $validated['locale'] ?? 'ar';

        $activeLayout = UiLayout::where('key', $validated['key'])
            ->where('platform', $platform)
            ->where('locale', $locale)
            ->first();

        // If it doesn't exist, we create it
        if (!$activeLayout) {
             $activeLayout = new UiLayout([
                'key' => $validated['key'],
                'platform' => $platform,
                'locale' => $locale,
                'is_active' => true,
             ]);
        }

        $payload = [
            'type' => 'column',
            'children' => $validated['widgets'],
        ];
        
        if (isset($validated['background_image'])) {
            $payload['background_image'] = $validated['background_image'];
        }
        
        $activeLayout->payload = $payload;
        $activeLayout->save();
        
        Cache::forget("ui_layout_{$validated['key']}_{$platform}_{$locale}");

        return response()->json(['success' => true, 'message' => 'تم الحفظ بنجاح']);
    }

    public function update(Request $request)
    {
        $validated = $request->validate([
            'widgets' => 'required|array',
            'platform' => 'nullable|string',
            'locale' => 'nullable|string',
        ]);

        $platform = $validated['platform'] ?? 'mobile';
        $locale = $validated['locale'] ?? 'ar';

        $activeLayout = UiLayout::where('key', 'home')
            ->where('platform', $platform)
            ->where('locale', $locale)
            ->first();

        if ($activeLayout) {
            $widgets = collect($validated['widgets'])->sortBy('order')->values()->toArray();
            $payload = $activeLayout->payload;
            $payload['children'] = $widgets;
            
            $activeLayout->update(['payload' => $payload]);
            Cache::forget("ui_layout_home_{$platform}_{$locale}");

            return back()->with('success', 'تم حفظ التغييرات بنجاح');
        }

        return back()->with('error', 'لم يتم العثور على التخطيط النشط');
    }

    public function addWidget(Request $request)
    {
        $validated = $request->validate([
            'type' => 'required|string',
            'title' => 'required|string',
            'platform' => 'nullable|string',
            'locale' => 'nullable|string',
        ]);

        $platform = $validated['platform'] ?? 'mobile';
        $locale = $validated['locale'] ?? 'ar';

        $activeLayout = UiLayout::where('key', 'home')
            ->where('platform', $platform)
            ->where('locale', $locale)
            ->first();

        if ($activeLayout) {
            $payload = $activeLayout->payload;
            $widgets = $payload['children'] ?? [];
            $maxOrder = collect($widgets)->max('order') ?? 0;

            $newWidget = [
                'type' => $validated['type'],
                'title' => $validated['title'],
                'order' => $maxOrder + 1,
                'is_active' => true,
            ];

            $widgets[] = $newWidget;
            $payload['children'] = $widgets;

            $activeLayout->update(['payload' => $payload]);
            Cache::forget("ui_layout_home_{$platform}_{$locale}");

            return back()->with('success', 'تم إضافة الويدجت بنجاح');
        }

        return back()->with('error', 'لم يتم العثور على التخطيط النشط');
    }

    public function deleteWidget(Request $request, $index)
    {
        $activeLayout = UiLayout::where('key', 'home')
            ->where('is_active', true)
            ->first();

        if ($activeLayout) {
            $payload = $activeLayout->payload;
            $widgets = $payload['children'] ?? [];
            
            if (isset($widgets[$index])) {
                unset($widgets[$index]);
                $widgets = array_values($widgets); // Re-index array
                $payload['children'] = $widgets;

                $activeLayout->update(['payload' => $payload]);
                Cache::forget('ui_layout_home');

                return back()->with('success', 'تم حذف الويدجت بنجاح');
            }
        }

        return back()->with('error', 'فشل حذف الويدجت');
    }
}
