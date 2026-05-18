<x-layouts.admin title="لوحة التحكم">
    <div class="space-y-6">
        <!-- Page Header -->
        <div>
            <h1 class="text-3xl font-bold text-slate-900">لوحة التحكم</h1>
            <p class="text-slate-600 mt-1">نظرة عامة على نظام Mashoar</p>
        </div>

        <!-- Stats Grid -->
        <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
            <x-ui.card>
                <div class="flex items-center justify-between">
                    <div>
                        <p class="text-sm font-medium text-slate-600">إجمالي المستخدمين</p>
                        <p class="text-3xl font-bold text-slate-900 mt-2">{{ number_format($stats['total_users']) }}</p>
                    </div>
                    <div class="p-3 bg-blue-100 rounded-lg">
                        <svg class="w-8 h-8 text-blue-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4.354a4 4 0 110 5.292M15 21H3v-1a6 6 0 0112 0v1zm0 0h6v-1a6 6 0 00-9-5.197M13 7a4 4 0 11-8 0 4 4 0 018 0z"/>
                        </svg>
                    </div>
                </div>
            </x-ui.card>

            <x-ui.card>
                <div class="flex items-center justify-between">
                    <div>
                        <p class="text-sm font-medium text-slate-600">السائقين</p>
                        <p class="text-3xl font-bold text-slate-900 mt-2">{{ number_format($stats['total_drivers']) }}</p>
                        <x-ui.badge variant="warning" class="mt-2">
                            {{ $stats['pending_drivers'] }} بانتظار التحقق
                        </x-ui.badge>
                    </div>
                    <div class="p-3 bg-green-100 rounded-lg">
                        <svg class="w-8 h-8 text-green-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"/>
                        </svg>
                    </div>
                </div>
            </x-ui.card>

            <x-ui.card>
                <div class="flex items-center justify-between">
                    <div>
                        <p class="text-sm font-medium text-slate-600">الرحلات النشطة</p>
                        <p class="text-3xl font-bold text-slate-900 mt-2">{{ number_format($stats['active_trips']) }}</p>
                    </div>
                    <div class="p-3 bg-yellow-100 rounded-lg">
                        <svg class="w-8 h-8 text-yellow-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 10V3L4 14h7v7l9-11h-7z"/>
                        </svg>
                    </div>
                </div>
            </x-ui.card>

            <x-ui.card>
                <div class="flex items-center justify-between">
                    <div>
                        <p class="text-sm font-medium text-slate-600">إجمالي العمولات</p>
                        <p class="text-3xl font-bold text-slate-900 mt-2">{{ number_format($stats['total_revenue']) }} ر.ي</p>
                    </div>
                    <div class="p-3 bg-purple-100 rounded-lg">
                        <svg class="w-8 h-8 text-purple-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8c-1.657 0-3 .895-3 2s1.343 2 3 2 3 .895 3 2-1.343 2-3 2m0-8c1.11 0 2.08.402 2.599 1M12 8V7m0 1v8m0 0v1m0-1c-1.11 0-2.08-.402-2.599-1M21 12a9 9 0 11-18 0 9 9 0 0118 0z"/>
                        </svg>
                    </div>
                </div>
            </x-ui.card>
        </div>

        <!-- Chart -->
        <x-ui.card>
            <x-slot name="header">
                <h3 class="text-lg font-semibold">الرحلات خلال آخر 7 أيام</h3>
            </x-slot>
            
            <canvas id="tripsChart" height="80"></canvas>
        </x-ui.card>

        <!-- Recent Trips -->
        <x-ui.card>
            <x-slot name="header">
                <h3 class="text-lg font-semibold">آخر الرحلات</h3>
            </x-slot>

            <x-ui.table>
                <thead class="border-b border-slate-200">
                    <tr>
                        <th class="text-right p-4 font-medium text-slate-600">رقم الرحلة</th>
                        <th class="text-right p-4 font-medium text-slate-600">الراكب</th>
                        <th class="text-right p-4 font-medium text-slate-600">السائق</th>
                        <th class="text-right p-4 font-medium text-slate-600">الحالة</th>
                        <th class="text-right p-4 font-medium text-slate-600">السعر</th>
                        <th class="text-right p-4 font-medium text-slate-600">التاريخ</th>
                    </tr>
                </thead>
                <tbody>
                    @forelse($recentTrips as $trip)
                        <tr class="border-b border-slate-100">
                            <td class="p-4">#{{ $trip->id }}</td>
                            <td class="p-4">{{ $trip->rider->name ?? 'غير معروف' }}</td>
                            <td class="p-4">{{ $trip->driver->user->name ?? $trip->driver->full_name ?? 'لم يتم التعيين' }}</td>
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
                            <td class="p-4">{{ number_format($trip->accepted_price ?? $trip->offered_price) }} ر.ي</td>
                            <td class="p-4 text-sm text-slate-600">{{ $trip->created_at->diffForHumans() }}</td>
                        </tr>
                    @empty
                        <tr>
                            <td colspan="6" class="p-8 text-center text-slate-500">لا توجد رحلات</td>
                        </tr>
                    @endforelse
                </tbody>
            </x-ui.table>
        </x-ui.card>
    </div>

    <script>
        // Trips Chart
        const ctx = document.getElementById('tripsChart').getContext('2d');
        const chartData = @json($tripsChart);
        
        new Chart(ctx, {
            type: 'line',
            data: {
                labels: Object.keys(chartData),
                datasets: [{
                    label: 'عدد الرحلات',
                    data: Object.values(chartData),
                    borderColor: 'rgb(59, 130, 246)',
                    backgroundColor: 'rgba(59, 130, 246, 0.1)',
                    tension: 0.4,
                    fill: true
                }]
            },
            options: {
                responsive: true,
                maintainAspectRatio: true,
                plugins: {
                    legend: {
                        display: false
                    }
                },
                scales: {
                    y: {
                        beginAtZero: true,
                        ticks: {
                            stepSize: 1
                        }
                    }
                }
            }
        });
    </script>
</x-layouts.admin>
