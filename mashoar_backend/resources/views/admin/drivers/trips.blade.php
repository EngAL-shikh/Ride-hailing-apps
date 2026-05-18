<x-layouts.admin title="سجل رحلات السائق: {{ $driver->full_name }}">
    <div class="space-y-6">
        <!-- Breadcrumbs -->
        <div class="flex items-center justify-between">
            <div class="flex items-center gap-2 text-sm text-slate-600">
                <a href="{{ route('admin.drivers.index') }}" class="hover:text-blue-600">السائقين</a>
                <span>/</span>
                <a href="{{ route('admin.drivers.show', $driver) }}" class="hover:text-blue-600">{{ $driver->full_name }}</a>
                <span>/</span>
                <span class="text-slate-900 font-medium">سجل الرحلات</span>
            </div>
        </div>

        <x-ui.card title="سجل جميع الرحلات ({{ $trips->total() }})">
            <x-ui.table>
                <thead>
                    <tr class="text-right border-b border-slate-100">
                        <th class="p-4 text-xs font-bold text-slate-500 uppercase">الرحلة</th>
                        <th class="p-4 text-xs font-bold text-slate-500 uppercase">الراكب</th>
                        <th class="p-4 text-xs font-bold text-slate-500 uppercase">السعر المقبول</th>
                        <th class="p-4 text-xs font-bold text-slate-500 uppercase">العمولة</th>
                        <th class="p-4 text-xs font-bold text-slate-500 uppercase">أرباح السائق</th>
                        <th class="p-4 text-xs font-bold text-slate-500 uppercase">الحالة</th>
                        <th class="p-4 text-xs font-bold text-slate-500 uppercase">التاريخ</th>
                        <th class="p-4 text-xs font-bold text-slate-500 uppercase">الإجراءات</th>
                    </tr>
                </thead>
                <tbody>
                    @forelse($trips as $trip)
                        <tr class="border-b border-slate-50 hover:bg-slate-50/50 transition-colors">
                            <td class="p-4 text-sm font-medium text-slate-900">#{{ $trip->id }}</td>
                            <td class="p-4 text-sm text-slate-600">{{ $trip->rider->full_name ?? $trip->rider->name ?? 'غير معروف' }}</td>
                            <td class="p-4 text-sm font-mono font-bold text-blue-600">{{ number_format($trip->accepted_price, 0) }}</td>
                            <td class="p-4 text-sm font-mono text-red-500">{{ number_format($trip->commission_amount, 0) }}</td>
                            <td class="p-4 text-sm font-mono text-green-600 font-bold">{{ number_format($trip->accepted_price - $trip->commission_amount, 0) }}</td>
                            <td class="p-4">
                                @if($trip->status === 'completed')
                                    <span class="text-[10px] px-2 py-0.5 rounded bg-green-100 text-green-700 font-bold uppercase">مكتملة</span>
                                @elseif($trip->status === 'cancelled')
                                    <span class="text-[10px] px-2 py-0.5 rounded bg-red-100 text-red-700 font-bold uppercase">ملغية</span>
                                @elseif($trip->status === 'in_progress')
                                    <span class="text-[10px] px-2 py-0.5 rounded bg-blue-100 text-blue-700 font-bold uppercase">قيد التنفيذ</span>
                                @else
                                    <span class="text-[10px] px-2 py-0.5 rounded bg-slate-100 text-slate-700 font-bold uppercase">{{ $trip->status }}</span>
                                @endif
                            </td>
                            <td class="p-4 text-xs text-slate-500">{{ $trip->created_at->format('Y/m/d H:i') }}</td>
                            <td class="p-4 text-left">
                                <a href="{{ route('admin.trips.show', $trip) }}" class="text-blue-600 hover:text-blue-800 text-xs font-bold">عرض التفاصيل</a>
                            </td>
                        </tr>
                    @empty
                        <tr>
                            <td colspan="8" class="p-12 text-center text-slate-400">لا توجد رحلات مسجلة لهذا السائق</td>
                        </tr>
                    @endforelse
                </tbody>
            </x-ui.table>

            <div class="p-4 border-t border-slate-100">
                {{ $trips->links() }}
            </div>
        </x-ui.card>
    </div>
</x-layouts.admin>
