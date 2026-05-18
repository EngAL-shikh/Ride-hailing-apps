<x-layouts.admin title="إدارة المحافظ">
    <div class="space-y-6">
        <!-- Page Header -->
        <div>
            <h1 class="text-3xl font-bold text-slate-900">إدارة المحافظ</h1>
            <p class="text-slate-600 mt-1">إدارة محافظ السائقين والعمليات المالية</p>
        </div>

        <!-- Manual Transaction Form -->
        <x-ui.card>
            <x-slot name="header">
                <h3 class="text-lg font-semibold">عملية يدوية</h3>
            </x-slot>

            <form action="{{ route('admin.wallets.transaction') }}" method="POST" class="space-y-4">
                @csrf
                
                <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                    <x-ui.input 
                        name="driver_phone" 
                        label="رقم هاتف السائق"
                        placeholder="967xxxxxxxxx"
                        required
                    />
                    
                    <x-ui.input 
                        name="amount" 
                        type="number"
                        step="0.01"
                        label="المبلغ (ر.ي)"
                        placeholder="1000"
                        required
                    />
                </div>

                <div>
                    <label class="block text-sm font-medium text-slate-700 mb-2">نوع العملية</label>
                    <div class="flex gap-4">
                        <label class="flex items-center">
                            <input type="radio" name="type" value="credit" checked class="ml-2">
                            <span>إضافة رصيد</span>
                        </label>
                        <label class="flex items-center">
                            <input type="radio" name="type" value="debit" class="ml-2">
                            <span>خصم رصيد</span>
                        </label>
                    </div>
                </div>

                <div>
                    <label for="note" class="block text-sm font-medium text-slate-700 mb-2">ملاحظة</label>
                    <textarea 
                        name="note" 
                        id="note"
                        rows="3"
                        class="w-full rounded-md border border-slate-300 px-3 py-2"
                        placeholder="سبب العملية..."
                        required
                    ></textarea>
                </div>

                <div class="flex justify-end">
                    <x-ui.button type="submit">
                        تنفيذ العملية
                    </x-ui.button>
                </div>
            </form>
        </x-ui.card>

        <!-- Drivers Wallets -->
        <x-ui.card>
            <x-slot name="header">
                <h3 class="text-lg font-semibold">محافظ السائقين</h3>
            </x-slot>

            <x-ui.table>
                <thead class="border-b border-slate-200">
                    <tr>
                        <th class="text-right p-4 font-medium text-slate-600">السائق</th>
                        <th class="text-right p-4 font-medium text-slate-600">رقم الهاتف</th>
                        <th class="text-right p-4 font-medium text-slate-600">الرصيد</th>
                        <th class="text-right p-4 font-medium text-slate-600">الحالة</th>
                    </tr>
                </thead>
                <tbody>
                    @forelse($drivers as $driver)
                        <tr class="border-b border-slate-100">
                            <td class="p-4">{{ $driver->user->name ?? 'غير معروف' }}</td>
                            <td class="p-4 font-mono">{{ $driver->user->phone ?? 'N/A' }}</td>
                            <td class="p-4">
                                <span class="font-bold {{ $driver->wallet_balance < 0 ? 'text-red-600' : 'text-green-600' }}">
                                    {{ number_format($driver->wallet_balance, 2) }} ر.ي
                                </span>
                            </td>
                            <td class="p-4">
                                @if($driver->wallet_balance < 0)
                                    <x-ui.badge variant="danger">مديون</x-ui.badge>
                                @elseif($driver->wallet_balance > 0)
                                    <x-ui.badge variant="success">دائن</x-ui.badge>
                                @else
                                    <x-ui.badge variant="default">متوازن</x-ui.badge>
                                @endif
                            </td>
                        </tr>
                    @empty
                        <tr>
                            <td colspan="4" class="p-8 text-center text-slate-500">لا يوجد سائقين</td>
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
