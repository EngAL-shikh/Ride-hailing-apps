<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\PromoCode;
use Illuminate\Http\Request;

class PromoCodeController extends Controller
{
    public function index()
    {
        $promoCodes = PromoCode::withCount('usages')
            ->latest()
            ->paginate(20);

        return view('admin.promo-codes.index', compact('promoCodes'));
    }

    public function create()
    {
        return view('admin.promo-codes.create');
    }

    public function store(Request $request)
    {
        $validated = $request->validate([
            'code' => 'required|string|unique:promo_codes,code|max:50',
            'type' => 'required|in:percentage,fixed,free_ride',
            'value' => 'required|numeric|min:0',
            'min_trip_amount' => 'nullable|numeric|min:0',
            'max_discount' => 'nullable|numeric|min:0',
            'usage_limit_total' => 'nullable|integer|min:1',
            'usage_limit_per_user' => 'required|integer|min:1',
            'new_users_only' => 'boolean',
            'valid_from' => 'nullable|date',
            'valid_until' => 'nullable|date|after:valid_from',
            'description' => 'nullable|string|max:500',
        ]);

        $validated['code'] = strtoupper($validated['code']);
        $validated['new_users_only'] = $request->has('new_users_only');

        PromoCode::create($validated);

        return redirect()->route('admin.promo-codes.index')
            ->with('success', 'تم إنشاء كود الخصم بنجاح');
    }

    public function edit(PromoCode $promoCode)
    {
        return view('admin.promo-codes.edit', compact('promoCode'));
    }

    public function update(Request $request, PromoCode $promoCode)
    {
        $validated = $request->validate([
            'type' => 'required|in:percentage,fixed,free_ride',
            'value' => 'required|numeric|min:0',
            'min_trip_amount' => 'nullable|numeric|min:0',
            'max_discount' => 'nullable|numeric|min:0',
            'usage_limit_total' => 'nullable|integer|min:1',
            'usage_limit_per_user' => 'required|integer|min:1',
            'new_users_only' => 'boolean',
            'valid_from' => 'nullable|date',
            'valid_until' => 'nullable|date|after:valid_from',
            'is_active' => 'boolean',
            'description' => 'nullable|string|max:500',
        ]);

        $validated['new_users_only'] = $request->has('new_users_only');
        $validated['is_active'] = $request->has('is_active');

        $promoCode->update($validated);

        return redirect()->route('admin.promo-codes.index')
            ->with('success', 'تم تحديث كود الخصم بنجاح');
    }

    public function destroy(PromoCode $promoCode)
    {
        $promoCode->delete();

        return redirect()->route('admin.promo-codes.index')
            ->with('success', 'تم حذف كود الخصم بنجاح');
    }

    public function toggle(PromoCode $promoCode)
    {
        $promoCode->update(['is_active' => !$promoCode->is_active]);

        return back()->with('success', 'تم تحديث حالة الكود بنجاح');
    }
}
