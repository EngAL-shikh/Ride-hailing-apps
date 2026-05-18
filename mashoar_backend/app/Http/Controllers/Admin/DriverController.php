<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\DriverProfile;
use App\Models\User;
use App\Models\Trip;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Facades\DB;

class DriverController extends Controller
{
    // Force Deployment Sync v2 - Fix Relationship Error
    public function index(Request $request)
    {
        $status = $request->get('status', 'all');
        $search = $request->get('search');
        
        $query = DriverProfile::with(['user', 'wallet'])
            ->withCount([
                'trips as total_trips',
                'trips as completed_trips' => function ($q) {
                    $q->where('status', 'completed');
                },
            ])
            ->latest();
        
        // Apply status filter
        if ($status !== 'all') {
            $query->where('verification_status', $status);
        }
        
        // Apply search
        if ($search) {
            $query->where(function ($q) use ($search) {
                $q->where('full_name', 'like', "%{$search}%")
                  ->orWhere('bike_plate', 'like', "%{$search}%")
                  ->orWhereHas('user', function ($q) use ($search) {
                      $q->where('phone', 'like', "%{$search}%");
                  });
            });
        }
        
        $drivers = $query->paginate(20);
        
        // Get stats for all statuses
        $stats = [
            'all' => DriverProfile::count(),
            'pending' => DriverProfile::where('verification_status', 'pending')->count(),
            'approved' => DriverProfile::where('verification_status', 'approved')->count(),
            'rejected' => DriverProfile::where('verification_status', 'rejected')->count(),
            'online' => DriverProfile::where('is_online', true)->count(),
        ];
        
        return view('admin.drivers.index', compact('drivers', 'status', 'stats', 'search'));
    }

    public function show(DriverProfile $driver)
    {
        $driver->load(['user', 'wallet']);
        
        // Get driver statistics
        $stats = [
            'total_trips' => Trip::where('driver_id', $driver->user_id)->count(),
            'completed_trips' => Trip::where('driver_id', $driver->user_id)
                ->where('status', 'completed')
                ->count(),
            'cancelled_trips' => Trip::where('driver_id', $driver->user_id)
                ->where('status', 'cancelled')
                ->count(),
            'total_earnings' => Trip::where('driver_id', $driver->id)
                ->where('status', 'completed')
                ->selectRaw('SUM(accepted_price - commission_amount) as total')
                ->value('total') ?? 0,
            'avg_rating' => $driver->rating ?? 0,
            'wallet_balance' => $driver->wallet->balance ?? 0,
        ];
        
        // Get recent trips
        $recentTrips = Trip::where('driver_id', $driver->user_id)
            ->with('rider')
            ->latest()
            ->limit(10)
            ->get();
        
        // Get document URLs
        $documents = [
            'id_front' => $driver->id_card_front_path 
                ? Storage::disk('public_uploads')->url($driver->id_card_front_path) 
                : null,
            'id_back' => $driver->id_card_back_path 
                ? Storage::disk('public_uploads')->url($driver->id_card_back_path) 
                : null,
            'avatar' => $driver->avatar_path 
                ? Storage::disk('public_uploads')->url($driver->avatar_path) 
                : null,
        ];
        
        return view('admin.drivers.show', compact('driver', 'stats', 'recentTrips', 'documents'));
    }

    public function verify(Request $request, DriverProfile $driver)
    {
        $validated = $request->validate([
            'action' => 'required|in:approve,reject',
            'reason' => 'required_if:action,reject|nullable|string|max:500',
        ]);

        if ($validated['action'] === 'approve') {
            $driver->update([
                'verification_status' => 'approved',
                'verification_notes' => null,
            ]);
            
            $message = 'تم قبول السائق بنجاح';
        } else {
            $driver->update([
                'verification_status' => 'rejected',
                'verification_notes' => $validated['reason'],
            ]);
            
            $message = 'تم رفض السائق';
        }

        return back()->with('success', $message);
    }

    public function toggleStatus(DriverProfile $driver)
    {
        $driver->user->update([
            'is_active' => !$driver->user->is_active,
        ]);

        $status = $driver->user->is_active ? 'تم تفعيل' : 'تم تعطيل';
        return back()->with('success', "{$status} السائق بنجاح");
    }

    public function destroy(DriverProfile $driver)
    {
        DB::transaction(function () use ($driver) {
            // Delete related data
            $driver->user->tokens()->delete();
            $driver->user->delete();
            $driver->delete();
        });

        return redirect()->route('admin.drivers.index')->with('success', 'تم حذف السائق بنجاح');
    }

    public function edit(DriverProfile $driver)
    {
        $driver->load('user');
        return view('admin.drivers.edit', compact('driver'));
    }

    public function update(Request $request, DriverProfile $driver)
    {
        $validated = $request->validate([
            'full_name' => 'required|string|max:255',
            'phone' => 'required|string|max:20',
            'bike_plate' => 'required|string|max:50',
            'rating' => 'nullable|numeric|min:0|max:5',
            'verification_status' => 'required|in:pending,approved,rejected',
            'is_active' => 'required|boolean',
        ]);

        DB::transaction(function () use ($driver, $validated) {
            $driver->update([
                'full_name' => $validated['full_name'],
                'bike_plate' => $validated['bike_plate'],
                'rating' => $validated['rating'] ?? $driver->rating,
                'verification_status' => $validated['verification_status'],
            ]);

            $driver->user->update([
                'phone' => $validated['phone'],
                'is_active' => $validated['is_active'],
            ]);
        });

        return redirect()->route('admin.drivers.show', $driver)
            ->with('success', 'تم تحديث بيانات السائق بنجاح');
    }

    public function trips(DriverProfile $driver)
    {
        $trips = Trip::where('driver_id', $driver->id)
            ->with(['rider'])
            ->latest()
            ->paginate(50);
            
        return view('admin.drivers.trips', compact('driver', 'trips'));
    }
}
