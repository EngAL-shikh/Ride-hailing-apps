<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\SystemSetting;
use App\Services\SettingsService;
use Illuminate\Http\Request;

class SettingsController extends Controller
{
    public function __construct(
        private SettingsService $settings
    ) {}

    public function index(Request $request)
    {
        $tab = $request->get('tab', 'app');
        
        $groups = [
            'app' => 'إعدادات التطبيق',
            'pricing' => 'التسعير',
            'driver' => 'السائقين',
            'rider' => 'الركاب',
            'payment' => 'الدفع',
            'maps' => 'الخرائط',
            'features' => 'الميزات',
            'notifications' => 'الإشعارات',
        ];
        
        $settings = SystemSetting::where('group', $tab)->get();
        
        return view('admin.settings.index', compact('settings', 'tab', 'groups'));
    }

    public function update(Request $request)
    {
        $validated = $request->validate([
            'settings' => 'required|array',
            'settings.*' => 'nullable',
        ]);

        foreach ($validated['settings'] as $key => $value) {
            $setting = SystemSetting::where('key', $key)->first();
            
            if ($setting) {
                // Handle boolean values
                if ($setting->type === 'boolean') {
                    $value = $value === '1' || $value === 'on' ? '1' : '0';
                }
                
                $setting->update(['value' => $value]);
            }
        }

        // Clear settings cache
        cache()->forget('settings');

        return back()->with('success', 'تم حفظ الإعدادات بنجاح');
    }
}
