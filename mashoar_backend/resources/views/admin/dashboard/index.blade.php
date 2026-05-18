<x-layouts.admin title="لوحة التحكم">
    <div class="space-y-6">
        <!-- Page Header -->
        <div class="flex items-center justify-between">
            <div>
                <h1 class="text-3xl font-bold text-slate-900">لوحة التحكم</h1>
                <p class="text-slate-600 mt-1">نظرة عامة على النظام</p>
            </div>
            
            <form action="{{ route('admin.sync-design') }}" method="POST">
                @csrf
                <x-ui.button type="submit" variant="destructive" class="gap-2">
                    <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15"/>
                    </svg>
                    مزامنة التصميم المحلي (V29)
                </x-ui.button>
            </form>
        </div>

        <!-- Stats Grid -->
        <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
            <x-ui.card>
                <div class="flex items-center justify-between">
                    <div>
                        <p class="text-sm text-slate-600">إجمالي المستخدمين</p>
                        <p class="text-3xl font-bold text-slate-900">{{ number_format($stats['total_users']) }}</p>
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
                        <p class="text-sm text-slate-600">إجمالي السائقين</p>
                        <p class="text-3xl font-bold text-slate-900">{{ number_format($stats['total_drivers']) }}</p>
                        <p class="text-xs text-orange-600 mt-1">{{ $stats['pending_drivers'] }} بانتظار التحقق</p>
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
                        <p class="text-sm text-slate-600">رحلات نشطة</p>
                        <p class="text-3xl font-bold text-blue-600">{{ number_format($stats['active_trips']) }}</p>
                    </div>
                    <div class="p-3 bg-blue-100 rounded-lg">
                        <svg class="w-8 h-8 text-blue-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 10V3L4 14h7v7l9-11h-7z"/>
                        </svg>
                    </div>
                </div>
            </x-ui.card>

            <x-ui.card>
                <div class="flex items-center justify-between">
                    <div>
                        <p class="text-sm text-slate-600">رحلات مكتملة</p>
                        <p class="text-3xl font-bold text-green-600">{{ number_format($stats['completed_trips']) }}</p>
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
                        <p class="text-sm text-slate-600">إجمالي الإيرادات</p>
                        <p class="text-3xl font-bold text-purple-600">{{ number_format($stats['total_revenue']) }}</p>
                        <p class="text-xs text-slate-500 mt-1">ر.ي</p>
                    </div>
                    <div class="p-3 bg-purple-100 rounded-lg">
                        <svg class="w-8 h-8 text-purple-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8c-1.657 0-3 .895-3 2s1.343 2 3 2 3 .895 3 2-1.343 2-3 2m0-8c1.11 0 2.08.402 2.599 1M12 8V7m0 1v8m0 0v1m0-1c-1.11 0-2.08-.402-2.599-1M21 12a9 9 0 11-18 0 9 9 0 0118 0z"/>
                        </svg>
                    </div>
                </div>
            </x-ui.card>

            <x-ui.card>
                <div class="flex items-center justify-between">
                    <div>
                        <p class="text-sm text-slate-600">توزيع الرحلات</p>
                        <div class="mt-2 space-y-1">
                            <p class="text-xs"><span class="font-semibold">مزايدة:</span> {{ $tripStats['bidding'] }}</p>
                            <p class="text-xs"><span class="font-semibold">معينة:</span> {{ $tripStats['assigned'] }}</p>
                            <p class="text-xs"><span class="font-semibold">جارية:</span> {{ $tripStats['in_progress'] }}</p>
                            <p class="text-xs"><span class="font-semibold">ملغاة:</span> {{ $tripStats['cancelled'] }}</p>
                        </div>
                    </div>
                    <div class="p-3 bg-slate-100 rounded-lg">
                        <svg class="w-8 h-8 text-slate-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 01-2 2h-2a2 2 0 01-2-2z"/>
                        </svg>
                    </div>
                </div>
            </x-ui.card>
        </div>

        <div class="grid grid-cols-1 lg:grid-cols-2 gap-6">
            <!-- Revenue Chart -->
            <x-ui.card>
                <h2 class="text-lg font-semibold mb-4">الإيرادات (آخر 7 أيام)</h2>
                <div style="height: 300px; max-height: 300px; position: relative;">
                    <canvas id="revenueChart"></canvas>
                </div>
            </x-ui.card>

            <!-- Top Drivers -->
            <x-ui.card>
                <h2 class="text-lg font-semibold mb-4">أفضل السائقين</h2>
                <div class="space-y-3">
                    @forelse($topDrivers as $driver)
                        <div class="flex items-center justify-between p-3 bg-slate-50 rounded-lg">
                            <div>
                                <p class="font-medium">{{ $driver->user->name ?? $driver->full_name }}</p>
                                <p class="text-sm text-slate-500">{{ $driver->completed_trips }} رحلة مكتملة</p>
                            </div>
                            <div class="text-right">
                                <p class="text-sm font-semibold">⭐ {{ number_format($driver->rating ?? 0, 1) }}</p>
                            </div>
                        </div>
                    @empty
                        <p class="text-center text-slate-500 py-4">لا توجد بيانات</p>
                    @endforelse
                </div>
            </x-ui.card>
        </div>

        <!-- Recent Trips -->
        <x-ui.card>
            <h2 class="text-lg font-semibold mb-4">الرحلات الأخيرة</h2>
            <x-ui.table>
                <thead class="border-b border-slate-200">
                    <tr>
                        <th class="text-right p-3 font-medium text-slate-600">#</th>
                        <th class="text-right p-3 font-medium text-slate-600">الراكب</th>
                        <th class="text-right p-3 font-medium text-slate-600">السائق</th>
                        <th class="text-right p-3 font-medium text-slate-600">السعر</th>
                        <th class="text-right p-3 font-medium text-slate-600">الحالة</th>
                        <th class="text-right p-3 font-medium text-slate-600">الوقت</th>
                    </tr>
                </thead>
                <tbody>
                    @forelse($recentTrips as $trip)
                        <tr class="border-b border-slate-100">
                            <td class="p-3">#{{ $trip->id }}</td>
                            <td class="p-3">{{ $trip->rider->name ?? 'غير معروف' }}</td>
                            <td class="p-3">{{ $trip->driver->user->name ?? $trip->driver->full_name ?? 'لم يتم التعيين' }}</td>
                            <td class="p-3">{{ number_format($trip->accepted_price ?? $trip->offered_price) }} ر.ي</td>
                            <td class="p-3">
                                @php
                                    $statusVariants = ['bidding' => 'info', 'assigned' => 'warning', 'in_progress' => 'warning', 'completed' => 'success', 'cancelled' => 'danger'];
                                    $statusLabels = ['bidding' => 'مزايدة', 'assigned' => 'معين', 'in_progress' => 'جاري', 'completed' => 'مكتمل', 'cancelled' => 'ملغي'];
                                @endphp
                                <x-ui.badge :variant="$statusVariants[$trip->status] ?? 'default'">
                                    {{ $statusLabels[$trip->status] ?? $trip->status }}
                                </x-ui.badge>
                            </td>
                            <td class="p-3 text-sm">{{ $trip->created_at->diffForHumans() }}</td>
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
        // Revenue Chart - FIXED VERSION
        const revenueCtx = document.getElementById('revenueChart');
        if (revenueCtx) {
            const revenueData = @json($revenueData ?? []);
            
            // Destroy existing chart if any
            if (window.revenueChartInstance) {
                window.revenueChartInstance.destroy();
            }
            
            // Only render if we have valid data
            if (Array.isArray(revenueData) && revenueData.length > 0) {
                window.revenueChartInstance = new Chart(revenueCtx.getContext('2d'), {
                    type: 'bar',
                    data: {
                        labels: revenueData.map(d => d.date || ''),
                        datasets: [{
                            label: 'الإيرادات (ر.ي)',
                            data: revenueData.map(d => parseFloat(d.revenue) || 0),
                            backgroundColor: 'rgba(59, 130, 246, 0.8)',
                            borderColor: 'rgb(59, 130, 246)',
                            borderWidth: 2,
                            borderRadius: 8,
                            hoverBackgroundColor: 'rgba(59, 130, 246, 1)',
                        }]
                    },
                    options: {
                        responsive: true,
                        maintainAspectRatio: true,
                        aspectRatio: 2,
                        plugins: {
                            legend: {
                                display: false
                            },
                            tooltip: {
                                backgroundColor: 'rgba(0, 0, 0, 0.8)',
                                padding: 12,
                                titleFont: { size: 14 },
                                bodyFont: { size: 13 },
                                cornerRadius: 8,
                            }
                        },
                        scales: {
                            y: {
                                beginAtZero: true,
                                grid: {
                                    color: 'rgba(0, 0, 0, 0.05)',
                                }
                            },
                            x: {
                                grid: {
                                    display: false
                                }
                            }
                        }
                    }
                });
            } else {
                revenueCtx.parentElement.innerHTML = '<p class="text-center text-slate-500 py-8">لا توجد بيانات للعرض</p>';
            }
        }
    </script>
</x-layouts.admin>
