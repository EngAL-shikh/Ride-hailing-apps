<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\PromoCode;
use Illuminate\Http\Request;

class PromoCodeController extends Controller
{
    /**
     * Validate promo code before applying
     */
    public function validate(Request $request)
    {
        $request->validate([
            'code' => 'required|string',
            'trip_amount' => 'required|numeric|min:0',
        ]);

        $code = strtoupper($request->input('code'));
        $tripAmount = $request->input('trip_amount');

        $promo = PromoCode::where('code', $code)
            ->where('is_active', true)
            ->first();

        if (!$promo) {
            return response()->json([
                'valid' => false,
                'message' => 'كود الخصم غير صحيح',
            ], 404);
        }

        // Check validity period
        if ($promo->valid_from && now()->lt($promo->valid_from)) {
            return response()->json([
                'valid' => false,
                'message' => 'كود الخصم غير صالح بعد',
            ], 400);
        }

        if ($promo->valid_until && now()->gt($promo->valid_until)) {
            return response()->json([
                'valid' => false,
                'message' => 'كود الخصم منتهي الصلاحية',
            ], 400);
        }

        // Check total usage limit
        if ($promo->usage_limit_total && $promo->usages_count >= $promo->usage_limit_total) {
            return response()->json([
                'valid' => false,
                'message' => 'تم استخدام هذا الكود بالكامل',
            ], 400);
        }

        // Check per-user usage limit
        $userUsageCount = $promo->usages()
            ->where('user_id', auth()->id())
            ->count();

        if ($promo->usage_limit_per_user && $userUsageCount >= $promo->usage_limit_per_user) {
            return response()->json([
                'valid' => false,
                'message' => 'لقد استخدمت هذا الكود من قبل',
            ], 400);
        }

        // Check new users only
        if ($promo->new_users_only) {
            $userTripsCount = auth()->user()->trips()->count();
            if ($userTripsCount > 0) {
                return response()->json([
                    'valid' => false,
                    'message' => 'هذا الكود للمستخدمين الجدد فقط',
                ], 400);
            }
        }

        // Check minimum trip amount
        if ($promo->min_trip_amount && $tripAmount < $promo->min_trip_amount) {
            return response()->json([
                'valid' => false,
                'message' => "الحد الأدنى للرحلة {$promo->min_trip_amount} ر.ي",
            ], 400);
        }

        // Calculate discount
        $discount = $this->calculateDiscount($promo, $tripAmount);

        return response()->json([
            'valid' => true,
            'promo_code_id' => $promo->id,
            'code' => $promo->code,
            'type' => $promo->type,
            'discount' => $discount,
            'original_amount' => $tripAmount,
            'final_amount' => max(0, $tripAmount - $discount),
            'description' => $promo->description,
        ]);
    }

    /**
     * Apply promo code after trip completion
     */
    public function apply(Request $request)
    {
        $request->validate([
            'promo_code_id' => 'required|exists:promo_codes,id',
            'trip_id' => 'required|exists:trips,id',
            'discount_amount' => 'required|numeric|min:0',
        ]);

        $promo = PromoCode::findOrFail($request->promo_code_id);

        // Record usage
        $promo->usages()->create([
            'user_id' => auth()->id(),
            'trip_id' => $request->trip_id,
            'discount_amount' => $request->discount_amount,
        ]);

        return response()->json([
            'success' => true,
            'message' => 'تم تطبيق كود الخصم بنجاح',
        ]);
    }

    /**
     * Calculate discount based on promo type
     */
    private function calculateDiscount(PromoCode $promo, float $tripAmount): float
    {
        switch ($promo->type) {
            case 'percentage':
                $discount = ($tripAmount * $promo->value) / 100;
                if ($promo->max_discount) {
                    $discount = min($discount, $promo->max_discount);
                }
                return $discount;

            case 'fixed':
                return min($promo->value, $tripAmount);

            case 'free_ride':
                return $tripAmount;

            default:
                return 0;
        }
    }
}
