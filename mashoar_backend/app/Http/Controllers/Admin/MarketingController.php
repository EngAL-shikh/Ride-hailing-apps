<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\User;
use App\Models\DriverProfile;
use App\Services\FcmService;
use Illuminate\Http\Request;

class MarketingController extends Controller
{
    public function __construct(
        private FcmService $fcm
    ) {}

    public function index()
    {
        return view('admin.marketing.index');
    }

    public function send(Request $request)
    {
        $validated = $request->validate([
            'title' => 'required|string|max:100',
            'body' => 'required|string|max:500',
            'audience' => 'required|in:all,drivers,riders',
        ]);

        // Get FCM tokens based on audience (All tokens are in users table)
        $tokens = match($validated['audience']) {
            'drivers' => User::where('user_type', 'driver')->whereNotNull('fcm_token')->pluck('fcm_token'),
            'riders' => User::where('user_type', 'rider')->whereNotNull('fcm_token')->pluck('fcm_token'),
            default => User::whereNotNull('fcm_token')->whereIn('user_type', ['driver', 'rider'])->pluck('fcm_token')
        };

        $sentCount = 0;
        foreach ($tokens as $token) {
            try {
                $this->fcm->sendToToken($token, $validated['title'], $validated['body']);
                $sentCount++;
            } catch (\Exception $e) {
                \Log::error("Failed to send FCM to token: {$token}", ['error' => $e->getMessage()]);
            }
        }

        return back()->with('success', "تم إرسال الإشعار إلى {$sentCount} مستخدم");
    }
}
