<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\Trip;
use Illuminate\Http\Request;

class TripController extends Controller
{
    public function index(Request $request)
    {
        $status = $request->get('status', 'all');
        
        $query = Trip::with(['rider', 'driver.user'])->latest();
        
        $trips = match($status) {
            'live' => $query->whereIn('status', ['bidding', 'assigned', 'in_progress'])->paginate(20),
            'completed' => $query->where('status', 'completed')->paginate(20),
            'cancelled' => $query->where('status', 'cancelled')->paginate(20),
            default => $query->paginate(20),
        };
        
        $stats = [
            'total' => Trip::count(),
            'live' => Trip::whereIn('status', ['bidding', 'assigned', 'in_progress'])->count(),
            'completed' => Trip::where('status', 'completed')->count(),
            'cancelled' => Trip::where('status', 'cancelled')->count(),
        ];
        
        return view('admin.trips.index', compact('trips', 'status', 'stats'));
    }

    public function show(Trip $trip)
    {
        $trip->load(['rider', 'driver.user', 'bids.driver.user']);
        
        return view('admin.trips.show', compact('trip'));
    }
}
