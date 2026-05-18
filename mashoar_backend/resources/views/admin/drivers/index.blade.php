<x-layouts.admin title="إدارة السائقين">
    <div class="space-y-6">
        <!-- Page Header -->
        <div class="flex items-center justify-between">
            <div>
                <h1 class="text-3xl font-bold text-slate-900">إدارة السائقين</h1>
                <p class="text-slate-600 mt-1">التحقق من السائقين وإدارتهم</p>
            </div>
        </div>

        <!-- Tabs -->
        <div class="border-b border-slate-200">
            <nav class="flex gap-4">
                <a href="{{ route('admin.drivers.index', ['status' => 'pending']) }}" 
                   class="px-4 py-2 border-b-2 {{ $status === 'pending' ? 'border-blue-600 text-blue-600' : 'border-transparent text-slate-600 hover:text-slate-900' }}">
                    بانتظار التحقق
                </a>
                <a href="{{ route('admin.drivers.index', ['status' => 'approved']) }}" 
                   class="px-4 py-2 border-b-2 {{ $status === 'approved' ? 'border-blue-600 text-blue-600' : 'border-transparent text-slate-600 hover:text-slate-900' }}">
                    مقبول
                </a>
                <a href="{{ route('admin.drivers.index', ['status' => 'rejected']) }}" 
                   class="px-4 py-2 border-b-2 {{ $status === 'rejected' ? 'border-blue-600 text-blue-600' : 'border-transparent text-slate-600 hover:text-slate-900' }}">
                    مرفوض
                </a>
            </nav>
        </div>

        <!-- Drivers Table -->
        <x-ui.card>
            <x-ui.table>
                <thead class="border-b border-slate-200">
                    <tr>
                        <th class="text-right p-4 font-medium text-slate-600">الاسم</th>
                        <th class="text-right p-4 font-medium text-slate-600">رقم الهاتف</th>
                        <th class="text-right p-4 font-medium text-slate-600">رقم اللوحة</th>
                        <th class="text-right p-4 font-medium text-slate-600">الحالة</th>
                        <th class="text-right p-4 font-medium text-slate-600">الإجراءات</th>
                    </tr>
                </thead>
                <tbody>
                    @forelse($drivers as $driver)
                        <tr class="border-b border-slate-100">
                            <td class="p-4">{{ $driver->full_name ?? $driver->user->name ?? 'غير معروف' }}</td>
                            <td class="p-4 font-mono">{{ $driver->user->phone ?? 'N/A' }}</td>
                            <td class="p-4 font-mono">{{ $driver->bike_plate ?? 'N/A' }}</td>
                            <td class="p-4">
                                @if($driver->verification_status === 'approved')
                                    <x-ui.badge variant="success">مقبول</x-ui.badge>
                                @elseif($driver->verification_status === 'rejected')
                                    <x-ui.badge variant="danger">مرفوض</x-ui.badge>
                                @else
                                    <x-ui.badge variant="warning">بانتظار التحقق</x-ui.badge>
                                @endif
                            </td>
                            <td class="p-4">
                                <a href="{{ route('admin.drivers.show', $driver) }}" class="inline-flex items-center px-3 py-1.5 border border-slate-300 text-xs font-medium rounded-md shadow-sm text-slate-700 bg-white hover:bg-slate-50 transition-colors">
                                    عرض التفاصيل
                                </a>
                            </td>
                        </tr>
                    @empty
                        <tr>
                            <td colspan="5" class="p-8 text-center text-slate-500">لا يوجد سائقين</td>
                        </tr>
                    @endforelse
                </tbody>
            </x-ui.table>

            @if($drivers->hasPages())
                <div class="p-4 border-t border-slate-200">
                    {{ $drivers->links() }}
                </div>
            @endif
        </x-ui.card>
    </div>
</x-layouts.admin>
