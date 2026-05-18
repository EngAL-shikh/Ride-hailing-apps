<x-layouts.admin title="إدارة الرحلات">
    <div class="space-y-6">
        <div>
            <h1 class="text-3xl font-bold text-slate-900">إدارة الرحلات</h1>
            <p class="text-slate-600 mt-1">عرض ومراقبة جميع الرحلات</p>
        </div>

        <!-- Stats Cards -->
        <div class="grid grid-cols-1 md:grid-cols-4 gap-4">
            <x-ui.card>
                <div class="text-center">
                    <p class="text-sm text-slate-600">إجمالي الرحلات</p>
                    <p class="text-3xl font-bold text-slate-900">{{ number_format($stats['total']) }}</p>
                </div>
            </x-ui.card>
            <x-ui.card>
                <div class="text-center">
                    <p class="text-sm text-slate-600">رحلات مباشرة</p>
                    <p class="text-3xl font-bold text-blue-600">{{ number_format($stats['live']) }}</p>
                </div>
            </x-ui.card>
            <x-ui.card>
                <div class="text-center">
                    <p class="text-sm text-slate-600">مكتملة</p>
                    <p class="text-3xl font-bold text-green-600">{{ number_format($stats['completed']) }}</p>
                </div>
            </x-ui.card>
            <x-ui.card>
                <div class="text-center">
                    <p class="text-sm text-slate-600">ملغاة</p>
                    <p class="text-3xl font-bold text-red-600">{{ number_format($stats['cancelled']) }}</p>
                </div>
            </x-ui.card>
        </div>

        <!-- Filters -->
        <div class="border-b border-slate-200">
            <nav class="flex gap-4">
                <a href="{{ route('admin.trips.index', ['status' => 'all']) }}" 
                   class="px-4 py-2 border-b-2 {{ $status === 'all' ? 'border-blue-600 text-blue-600' : 'border-transparent text-slate-600 hover:text-slate-900' }}">
                    الكل
                </a>
                <a href="{{ route('admin.trips.index', ['status' => 'live']) }}" 
                   class="px-4 py-2 border-b-2 {{ $status === 'live' ? 'border-blue-600 text-blue-600' : 'border-transparent text-slate-600 hover:text-slate-900' }}">
                    مباشر
                </a>
                <a href="{{ route('admin.trips.index', ['status' => 'completed']) }}" 
                   class="px-4 py-2 border-b-2 {{ $status === 'completed' ? 'border-blue-600 text-blue-600' : 'border-transparent text-slate-600 hover:text-slate-900' }}">
                    مكتملة
                </a>
                <a href="{{ route('admin.trips.index', ['status' => 'cancelled']) }}" 
                   class="px-4 py-2 border-b-2 {{ $status === 'cancelled' ? 'border-blue-600 text-blue-600' : 'border-transparent text-slate-600 hover:text-slate-900' }}">
                    ملغاة
                </a>
            </nav>
        </div>

        <!-- Trips Table -->
        <x-ui.card>
            <x-ui.table>
                <thead class="border-b border-slate-200">
                    <tr>
                        <th class="text-right p-4 font-medium text-slate-600">#</th>
                        <th class="text-right p-4 font-medium text-slate-600">الراكب</th>
                        <th class="text-right p-4 font-medium text-slate-600">السائق</th>
                        <th class="text-right p-4 font-medium text-slate-600">السعر</th>
                        <th class="text-right p-4 font-medium text-slate-600">الحالة</th>
                        <th class="text-right p-4 font-medium text-slate-600">التاريخ</th>
                        <th class="text-right p-4 font-medium text-slate-600">الإجراءات</th>
                    </tr>
                </thead>
                <tbody>
                    @forelse($trips as $trip)
                        <tr class="border-b border-slate-100">
                            <td class="p-4">#{{ $trip->id }}</td>
                            <td class="p-4">{{ $trip->rider->name ?? 'غير معروف' }}</td>
                            <td class="p-4">{{ $trip->driver->user->name ?? $trip->driver->full_name ?? 'لم يتم التعيين' }}</td>
                            <td class="p-4">{{ number_format($trip->accepted_price ?? $trip->offered_price) }} ر.ي</td>
                            <td class="p-4">
                                @php
                                    $statusVariants = [
                                        'bidding' => 'info',
                                        'assigned' => 'warning',
                                        'in_progress' => 'warning',
                                        'completed' => 'success',
                                        'cancelled' => 'danger',
                                    ];
                                    $statusLabels = [
                                        'bidding' => 'مزايدة',
                                        'assigned' => 'معين',
                                        'in_progress' => 'جاري',
                                        'completed' => 'مكتمل',
                                        'cancelled' => 'ملغي',
                                    ];
                                @endphp
                                <x-ui.badge :variant="$statusVariants[$trip->status] ?? 'default'">
                                    {{ $statusLabels[$trip->status] ?? $trip->status }}
                                </x-ui.badge>
                            </td>
                            <td class="p-4 text-sm">{{ $trip->created_at->diffForHumans() }}</td>
                            <td class="p-4">
                                <a href="{{ route('admin.trips.show', $trip) }}">
                                    <x-ui.button variant="outline" size="sm">عرض</x-ui.button>
                                </a>
                            </td>
                        </tr>
                    @empty
                        <tr>
                            <td colspan="7" class="p-8 text-center text-slate-500">لا توجد رحلات</td>
                        </tr>
                    @endforelse
                </tbody>
            </x-ui.table>

            @if($trips->hasPages())
                <div class="p-4 border-t border-slate-200">
                    {{ $trips->links() }}
                </div>
            @endif
        </x-ui.card>
    </div>
</x-layouts.admin>
