<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\SystemSetting;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Http;

class FirebaseController extends Controller
{
    public function index()
    {
        $fcmSettings = [
            'fcm_server_key' => SystemSetting::where('key', 'fcm_server_key')->first()?->value ?? '',
            'fcm_project_id' => SystemSetting::where('key', 'fcm_project_id')->first()?->value ?? '',
            'fcm_sender_id' => SystemSetting::where('key', 'fcm_sender_id')->first()?->value ?? '',
        ];
        
        return view('admin.firebase.index', compact('fcmSettings'));
    }

    public function testNotification(Request $request)
    {
        $validated = $request->validate([
            'token' => 'required|string',
            'title' => 'required|string',
            'body' => 'required|string',
        ]);

        $serverKey = SystemSetting::where('key', 'fcm_server_key')->first()?->value;

        if (!$serverKey) {
            return back()->with('error', 'FCM Server Key غير محدد في الإعدادات');
        }

        try {
            $response = Http::withHeaders([
                'Authorization' => 'key=' . $serverKey,
                'Content-Type' => 'application/json',
            ])->post('https://fcm.googleapis.com/fcm/send', [
                'to' => $validated['token'],
                'notification' => [
                    'title' => $validated['title'],
                    'body' => $validated['body'],
                ],
            ]);

            if ($response->successful()) {
                return back()->with('success', 'تم إرسال الإشعار بنجاح');
            } else {
                return back()->with('error', 'فشل إرسال الإشعار: ' . $response->body());
            }
        } catch (\Exception $e) {
            return back()->with('error', 'خطأ: ' . $e->getMessage());
        }
    }
}
