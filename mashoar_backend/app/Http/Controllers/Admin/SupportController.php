<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\SupportTicket;
use Illuminate\Http\Request;

class SupportController extends Controller
{
    public function index(Request $request)
    {
        $status = $request->get('status', 'all');
        
        $query = SupportTicket::with(['user', 'assignedTo'])->latest();
        
        $tickets = match($status) {
            'open' => $query->where('status', 'open')->paginate(20),
            'in_progress' => $query->where('status', 'in_progress')->paginate(20),
            'resolved' => $query->where('status', 'resolved')->paginate(20),
            'closed' => $query->where('status', 'closed')->paginate(20),
            default => $query->paginate(20),
        };
        
        $stats = [
            'total' => SupportTicket::count(),
            'open' => SupportTicket::where('status', 'open')->count(),
            'in_progress' => SupportTicket::where('status', 'in_progress')->count(),
            'resolved' => SupportTicket::where('status', 'resolved')->count(),
        ];
        
        return view('admin.support.index', compact('tickets', 'status', 'stats'));
    }

    public function show(SupportTicket $ticket)
    {
        $ticket->load(['user', 'replies.user', 'assignedTo']);
        
        return view('admin.support.show', compact('ticket'));
    }

    public function updateStatus(Request $request, SupportTicket $ticket)
    {
        $validated = $request->validate([
            'status' => 'required|in:open,in_progress,resolved,closed',
        ]);

        $ticket->update($validated);

        return back()->with('success', 'تم تحديث حالة التذكرة');
    }

    public function reply(Request $request, SupportTicket $ticket)
    {
        $validated = $request->validate([
            'message' => 'required|string',
        ]);

        $ticket->replies()->create([
            'user_id' => auth()->id() ?? 1,
            'message' => $validated['message'],
            'is_admin' => true,
        ]);

        return back()->with('success', 'تم إرسال الرد');
    }
}
