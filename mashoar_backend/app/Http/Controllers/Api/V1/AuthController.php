<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Requests\Auth\RegisterRequest;
use App\Http\Requests\Auth\RequestOtpRequest;
use App\Http\Requests\Auth\VerifyOtpRequest;
use App\Http\Resources\UserResource;
use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Str;

class AuthController extends Controller
{
    /**
     * Register a new user (phone-based). Password/email are generated internally.
     */
    public function register(RegisterRequest $request): JsonResponse
    {
        $phone = $this->normalizePhone($request->string('phone')->toString());

        $user = User::query()->forceCreate([
            'name' => $request->string('name')->toString(),
            'phone' => $phone,
            'type' => $request->string('type')->toString(),
            'fcm_token' => $request->string('fcm_token')->toString() ?: null,
            'is_active' => true,
            // Keep default schema happy (email/password required in base migration)
            'email' => $this->emailFromPhone($phone),
            'password' => Hash::make(Str::random(40)),
        ]);

        return response()->json([
            'message' => 'registered',
            'user' => new UserResource($user),
        ]);
    }

    /**
     * Request OTP for a phone number.
     */
    public function requestOtp(RequestOtpRequest $request): JsonResponse
    {
        $phone = $this->normalizePhone($request->string('phone')->toString());

        // Simple throttling per phone to reduce abuse on shared hosting.
        $throttleKey = "otp:req:{$phone}";
        $count = (int) Cache::get($throttleKey, 0);
        if ($count >= 3) {
            return response()->json(['message' => 'too_many_requests'], 429);
        }
        Cache::put($throttleKey, $count + 1, now()->addMinute());

        $user = User::query()->where('phone', $phone)->first();

        if (! $user) {
            $user = User::query()->forceCreate([
                'name' => $phone,
                'phone' => $phone,
                'type' => 'rider',
                'fcm_token' => null,
                'is_active' => true,
                'email' => $this->emailFromPhone($phone),
                'password' => Hash::make(Str::random(40)),
            ]);
        }

        $otp = (string) random_int(1000, 9999);
        $otpKey = $this->otpCacheKey($phone);
        Cache::put($otpKey, Hash::make($otp), now()->addMinutes(5));

        $payload = ['message' => 'otp_sent'];

        // For local/dev only: return OTP for testing.
        if (config('app.debug')) {
            $payload['otp_debug'] = $otp;
        }

        return response()->json($payload);
    }

    /**
     * Verify OTP and issue Sanctum token.
     */
    public function verifyOtp(VerifyOtpRequest $request): JsonResponse
    {
        $phone = $this->normalizePhone($request->string('phone')->toString());
        $otp = $request->string('otp')->toString();

        $otpKey = $this->otpCacheKey($phone);
        $hash = Cache::get($otpKey);
        if (!is_string($hash) || !Hash::check($otp, $hash)) {
            return response()->json(['message' => 'invalid_otp'], 422);
        }

        Cache::forget($otpKey);

        $user = User::where('phone', $phone)->first();
        if (!$user) {
            return response()->json(['message' => 'user_not_found'], 404);
        }

        if ($request->filled('fcm_token')) {
            $user->fcm_token = $request->string('fcm_token')->toString();
        }
        $user->is_active = true;
        $user->save();

        $deviceName = $request->string('device_name')->toString() ?: 'mobile';
        $token = $user->createToken($deviceName)->plainTextToken;

        return response()->json([
            'message' => 'authenticated',
            'token' => $token,
            'user' => new UserResource($user),
        ]);
    }

    /**
     * Update the user's FCM token (mobile token can rotate).
     */
    public function updateFcmToken(Request $request): JsonResponse
    {
        $user = $request->user();
        if (! $user) {
            return response()->json(['message' => 'forbidden'], 403);
        }

        $validated = $request->validate([
            'fcm_token' => ['required', 'string', 'max:5000'],
        ]);

        $user->fcm_token = (string) $validated['fcm_token'];
        $user->save();

        return response()->json(['message' => 'fcm_token_updated']);
    }

    /**
     * Logout by revoking the current access token.
     */
    public function logout(Request $request): JsonResponse
    {
        $user = $request->user();
        if ($user && method_exists($user, 'currentAccessToken') && $user->currentAccessToken()) {
            $user->currentAccessToken()->delete();
        }

        return response()->json(['message' => 'logged_out']);
    }

    private function otpCacheKey(string $phone): string
    {
        return "otp:code:{$phone}";
    }

    private function normalizePhone(string $phone): string
    {
        $digits = preg_replace('/\\D+/', '', $phone) ?: '';
        return $digits;
    }

    private function emailFromPhone(string $phone): string
    {
        return "{$phone}@mashoar.local";
    }
}
