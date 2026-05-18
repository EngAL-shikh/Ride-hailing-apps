<x-layouts.admin title="الدعم الفني">
    <div class="space-y-6">
        <div>
            <h1 class="text-3xl font-bold text-slate-900">تذاكر الدعم الفني</h1>
            <p class="text-slate-600 mt-1">إدارة طلبات الدعم</p>
        </div>

        <!-- Stats -->
        <div class="grid grid-cols-1 md:grid-cols-4 gap-4">
            <x-ui.card>
                <div class="text-center">
                    <p class="text-sm text-slate-600">إجمالي التذاكر</p>
                    <p class="text-3xl font-bold">{{ $stats['total'] }}</p>
                </div>
            </x-ui.card>
            <x-ui.card>
                <div class="text-center">
                    <p class="text-sm text-slate-600">مفتوحة</p>
                    <p class="text-3xl font-bold text-red-600">{{ $stats['open'] }}</p>
                </div>
            </x-ui.card>
            <x-ui.card>
                <div class="text-center">
                    <p class="text-sm text-slate-600">قيد المعالجة</p>
                    <p class="text-3xl font-bold text-orange-600">{{ $stats['in_progress'] }}</p>
                </div>
            </x-ui.card>
            <x-ui.card>
                <div class="text-center">
                    <p class="text-sm text-slate-600">محلولة</p>
                    <p class="text-3xl font-bold text-green-600">{{ $stats['resolved'] }}</p>
                </div>
            </x-ui.card>
        </div>

        <!-- Filters -->
        <div class="border-b border-slate-200">
            <nav class="flex gap-4">
                @foreach(['all' => 'الكل', 'open' => 'مفتوحة', 'in_progress' => 'قيد المعالجة', 'resolved' => 'محلولة', 'closed' => 'مغلقة'] as $key => $label)
                    <a href="{{ route('admin.support.index', ['status' => $key]) }}" 
                       class="px-4 py-2 border-b-2 {{ $status === $key ? 'border-blue-600 text-blue-600' : 'border-transparent text-slate-600 hover:text-slate-900' }}">
                        {{ $label }}
                    </a>
                @endforeach
            </nav>
        </div>

        <!-- Tickets Table -->
        <x-ui.card>
            <x-ui.table>
                <thead class="border-b border-slate-200">
                    <tr>
                        <th class="text-right p-4 font-medium text-slate-600">#</th>
                        <th class="text-right p-4 font-medium text-slate-600">الموضوع</th>
                        <th class="text-right p-4 font-medium text-slate-600">المستخدم</th>
                        <th class="text-right p-4 font-medium text-slate-600">الأولوية</th>
                        <th class="text-right p-4 font-medium text-slate-600">الحالة</th>
                        <th class="text-right p-4 font-medium text-slate-600">التاريخ</th>
                        <th class="text-right p-4 font-medium text-slate-600">الإجراءات</th>
                    </tr>
                </thead>
                <tbody>
                    @forelse($tickets as $ticket)
                        <tr class="border-b border-slate-100">
                            <td class="p-4">#{{ $ticket->id }}</td>
                            <td class="p-4">{{ $ticket->subject }}</td>
                            <td class="p-4">{{ $ticket->user->name }}</td>
                            <td class="p-4">
                                @php
                                    $priorityVariants = ['low' => 'default', 'medium' => 'info', 'high' => 'warning', 'urgent' => 'danger'];
                                    $priorityLabels = ['low' => 'منخفضة', 'medium' => 'متوسطة', 'high' => 'عالية', 'urgent' => 'عاجلة'];
                                @endphp
                                <x-ui.badge :variant="$priorityVariants[$ticket->priority]">
                                    {{ $priorityLabels[$ticket->priority] }}
                                </x-ui.badge>
                            </td>
                            <td class="p-4">
                                @php
                                    $statusVariants = ['open' => 'danger', 'in_progress' => 'warning', 'resolved' => 'success', 'closed' => 'default'];
                                    $statusLabels = ['open' => 'مفتوحة', 'in_progress' => 'قيد المعالجة', 'resolved' => 'محلولة', 'closed' => 'مغلقة'];
                                @endphp
                                <x-ui.badge :variant="$statusVariants[$ticket->status]">
                                    {{ $statusLabels[$ticket->status] }}
                                </x-ui.badge>
                            </td>
                            <td class="p-4 text-sm">{{ $ticket->created_at->diffForHumans() }}</td>
                            <td class="p-4">
                                <a href="{{ route('admin.support.show', $ticket) }}">
                                    <x-ui.button variant="outline" size="sm">عرض</x-ui.button>
                                </a>
                            </td>
                        </tr>
                    @empty
                        <tr>
                            <td colspan="7" class="p-8 text-center text-slate-500">لا توجد تذاكر</td>
                        </tr>
                    @endforelse
                </tbody>
            </x-ui.table>

            @if($tickets->hasPages())
                <div class="p-4 border-t border-slate-200">
                    {{ $tickets->links() }}
                </div>
            @endif
        </x-ui.card>
    </div>
</x-layouts.admin>
