<x-layouts.admin title="تفاصيل السائق: {{ $driver->full_name }}">
    <div class="space-y-6">
        <!-- Breadcrumbs & Actions -->
        <div class="flex items-center justify-between">
            <div class="flex items-center gap-2 text-sm text-slate-600">
                <a href="{{ route('admin.drivers.index') }}" class="hover:text-blue-600">السائقين</a>
                <span>/</span>
                <span class="text-slate-900 font-medium">{{ $driver->full_name }}</span>
            </div>
            <div class="flex gap-2">
                <a href="{{ route('admin.drivers.edit', $driver) }}" class="px-4 py-2 bg-white border border-slate-200 rounded-lg text-sm font-medium text-slate-700 hover:bg-slate-50 transition-colors">
                    تعديل البيانات
                </a>
            </div>
        </div>

        <div class="grid grid-cols-1 lg:grid-cols-3 gap-6">
            <!-- Left Column: Profile Card -->
            <div class="space-y-6">
                <x-ui.card>
                    <div class="flex flex-col items-center p-4">
                        <div class="w-32 h-32 rounded-full overflow-hidden bg-slate-100 border-4 border-white shadow-sm mb-4">
                            @if($driver->avatar_path)
                                <img src="{{ Storage::disk('public_uploads')->url($driver->avatar_path) }}" alt="Avatar" class="w-full h-full object-cover">
                            @else
                                <div class="w-full h-full flex items-center justify-center text-slate-400">
                                    <svg class="w-16 h-16" fill="currentColor" viewBox="0 0 20 20">
                                        <path fill-rule="evenodd" d="M10 9a3 3 0 100-6 3 3 0 000 6zm-7 9a7 7 0 1114 0H3z" clip-rule="evenodd" />
                                    </svg>
                                </div>
                            @endif
                        </div>
                        <h2 class="text-xl font-bold text-slate-900">{{ $driver->full_name }}</h2>
                        <p class="text-slate-500 font-mono text-sm mt-1">{{ $driver->user->phone }}</p>
                        
                        <div class="mt-4 flex gap-2">
                            @if($driver->verification_status === 'approved')
                                <x-ui.badge variant="success">مقبول</x-ui.badge>
                            @elseif($driver->verification_status === 'rejected')
                                <x-ui.badge variant="danger">مرفوض</x-ui.badge>
                            @else
                                <x-ui.badge variant="warning">بانتظار التحقق</x-ui.badge>
                            @endif

                            @if($driver->is_online)
                                <x-ui.badge variant="success">متصل حالياً</x-ui.badge>
                            @else
                                <x-ui.badge variant="secondary">غير متصل</x-ui.badge>
                            @endif
                        </div>
                    </div>

                    <div class="border-t border-slate-100 p-4 space-y-3">
                        <div class="flex justify-between text-sm">
                            <span class="text-slate-500">رقم اللوحة:</span>
                            <span class="font-bold text-slate-900">{{ $driver->bike_plate }}</span>
                        </div>
                        <div class="flex justify-between text-sm">
                            <span class="text-slate-500">التقييم:</span>
                            <div class="flex items-center gap-1">
                                <span class="font-bold text-slate-900">{{ number_format($driver->rating, 1) }}</span>
                                <svg class="w-4 h-4 text-yellow-400" fill="currentColor" viewBox="0 0 20 20">
                                    <path d="M9.049 2.927c.3-.921 1.603-.921 1.902 0l1.07 3.292a1 1 0 00.95.69h3.462c.969 0 1.371 1.24.588 1.81l-2.8 2.034a1 1 0 00-.364 1.118l1.07 3.292c.3.921-.755 1.688-1.54 1.118l-2.8-2.034a1 1 0 00-1.175 0l-2.8 2.034c-.784.57-1.838-.197-1.539-1.118l1.07-3.292a1 1 0 00-.364-1.118L2.98 8.72c-.783-.57-.38-1.81.588-1.81h3.461a1 1 0 00.951-.69l1.07-3.292z" />
                                </svg>
                            </div>
                        </div>
                        <div class="flex justify-between text-sm">
                            <span class="text-slate-500">تاريخ التسجيل:</span>
                            <span class="text-slate-900">{{ $driver->created_at->format('Y-m-d') }}</span>
                        </div>
                    </div>
                </x-ui.card>

                <!-- Statistics Grid -->
                <div class="grid grid-cols-2 gap-4">
                    <x-ui.card class="bg-blue-50/50 border-blue-100 p-4 text-center">
                        <p class="text-xs text-blue-600 font-medium mb-1">إجمالي الرحلات</p>
                        <p class="text-2xl font-bold text-blue-900">{{ $stats['total_trips'] }}</p>
                    </x-ui.card>
                    <x-ui.card class="bg-green-50/50 border-green-100 p-4 text-center">
                        <p class="text-xs text-green-600 font-medium mb-1">الرحلات المكتملة</p>
                        <p class="text-2xl font-bold text-green-900">{{ $stats['completed_trips'] }}</p>
                    </x-ui.card>
                    <x-ui.card class="bg-yellow-50/50 border-yellow-100 p-4 text-center">
                        <p class="text-xs text-yellow-600 font-medium mb-1">إجمالي الأرباح</p>
                        <p class="text-xl font-bold text-yellow-900 font-mono">{{ number_format($stats['total_earnings'], 0) }}</p>
                    </x-ui.card>
                    <x-ui.card class="bg-purple-50/50 border-purple-100 p-4 text-center">
                        <p class="text-xs text-purple-600 font-medium mb-1">رصيد المحفظة</p>
                        <p class="text-xl font-bold text-purple-900 font-mono">{{ number_format($stats['wallet_balance'], 0) }}</p>
                    </x-ui.card>
                </div>
            </div>

            <!-- Right Column: Documents & Verification -->
            <div class="lg:col-span-2 space-y-6">
                <!-- Verification Status Section -->
                @if($driver->verification_status === 'pending')
                    <div class="bg-yellow-50 border border-yellow-200 rounded-xl p-6 shadow-sm">
                        <div class="flex items-start gap-4">
                            <div class="p-3 bg-yellow-100 rounded-lg text-yellow-600">
                                <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m5.618-4.016A11.955 11.955 0 0112 2.944a11.955 11.955 0 01-8.618 3.04A12.02 12.02 0 003 9c0 5.591 3.824 10.29 9 11.622 5.176-1.332 9-6.03 9-11.622 0-1.042-.133-2.052-.382-3.016z" />
                                </svg>
                            </div>
                            <div class="flex-1">
                                <h3 class="text-lg font-bold text-yellow-900">بانتظار التحقق من الهوية</h3>
                                <p class="text-yellow-700 text-sm mt-1">يرجى مراجعة الوثائق أدناه والموافقة على السائق أو رفضه مع ذكر السبب.</p>
                                
                                <form action="{{ route('admin.drivers.verify', $driver) }}" method="POST" class="mt-6" x-data="{ action: 'approve' }">
                                    @csrf
                                    <div class="flex gap-6 mb-4">
                                        <label class="flex items-center gap-2 cursor-pointer group">
                                            <input type="radio" name="action" value="approve" x-model="action" class="w-4 h-4 text-blue-600 border-slate-300 focus:ring-blue-500">
                                            <span class="text-sm font-medium text-slate-700 group-hover:text-slate-900">قبول وتفعيل</span>
                                        </label>
                                        <label class="flex items-center gap-2 cursor-pointer group">
                                            <input type="radio" name="action" value="reject" x-model="action" class="w-4 h-4 text-red-600 border-slate-300 focus:ring-red-500">
                                            <span class="text-sm font-medium text-slate-700 group-hover:text-slate-900">رفض الطلب</span>
                                        </label>
                                    </div>

                                    <div x-show="action === 'reject'" x-cloak class="mb-4">
                                        <textarea 
                                            name="reason" 
                                            rows="3" 
                                            class="w-full rounded-lg border-slate-300 shadow-sm focus:border-red-500 focus:ring-red-500 text-sm"
                                            placeholder="اكتب سبب الرفض هنا ليتم إرساله للسائق..."
                                        ></textarea>
                                    </div>

                                    <button type="submit" :class="action === 'approve' ? 'bg-green-600 hover:bg-green-700' : 'bg-red-600 hover:bg-red-700'" class="px-6 py-2.5 rounded-lg text-white font-bold text-sm transition-colors shadow-sm">
                                        <span x-text="action === 'approve' ? 'تأكيد الموافقة وتفعيل الحساب' : 'تأكيد الرفض'"></span>
                                    </button>
                                </form>
                            </div>
                        </div>
                    </div>
                @elseif($driver->verification_status === 'rejected')
                    <div class="bg-red-50 border border-red-200 rounded-xl p-6">
                        <h3 class="text-lg font-bold text-red-900">تم رفض هذا السائق</h3>
                        <p class="text-red-700 text-sm mt-1">سبب الرفض: {{ $driver->verification_notes }}</p>
                        <form action="{{ route('admin.drivers.verify', $driver) }}" method="POST" class="mt-4">
                            @csrf
                            <input type="hidden" name="action" value="approve">
                            <button type="submit" class="text-sm font-bold text-blue-600 hover:underline">الموافقة عليه الآن وإلغاء الرفض</button>
                        </form>
                    </div>
                @endif

                <!-- Documents Section -->
                <x-ui.card title="وثائق الهوية">
                    <div class="grid grid-cols-1 md:grid-cols-2 gap-6 p-4">
                        <!-- ID Front -->
                        <div class="space-y-2">
                            <p class="text-sm font-bold text-slate-700">صورة الهوية (الأمامية)</p>
                            @if($driver->id_card_front_path)
                                <div class="relative group aspect-[1.6/1] bg-slate-100 rounded-xl overflow-hidden border border-slate-200">
                                    <img src="{{ Storage::disk('public_uploads')->url($driver->id_card_front_path) }}" alt="ID Front" class="w-full h-full object-cover">
                                    <a href="{{ Storage::disk('public_uploads')->url($driver->id_card_front_path) }}" target="_blank" class="absolute inset-0 bg-black/40 flex items-center justify-center opacity-0 group-hover:opacity-100 transition-opacity">
                                        <span class="text-white font-bold text-sm bg-black/50 px-4 py-2 rounded-full">عرض بالحجم الكامل</span>
                                    </a>
                                </div>
                            @else
                                <div class="aspect-[1.6/1] bg-slate-50 rounded-xl border-2 border-dashed border-slate-200 flex flex-col items-center justify-center text-slate-400">
                                    <svg class="w-12 h-12 mb-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
                                    </svg>
                                    <p class="text-xs">لم يتم رفع الصورة</p>
                                </div>
                            @endif
                        </div>

                        <!-- ID Back -->
                        <div class="space-y-2">
                            <p class="text-sm font-bold text-slate-700">صورة الهوية (الخلفية)</p>
                            @if($driver->id_card_back_path)
                                <div class="relative group aspect-[1.6/1] bg-slate-100 rounded-xl overflow-hidden border border-slate-200">
                                    <img src="{{ Storage::disk('public_uploads')->url($driver->id_card_back_path) }}" alt="ID Back" class="w-full h-full object-cover">
                                    <a href="{{ Storage::disk('public_uploads')->url($driver->id_card_back_path) }}" target="_blank" class="absolute inset-0 bg-black/40 flex items-center justify-center opacity-0 group-hover:opacity-100 transition-opacity">
                                        <span class="text-white font-bold text-sm bg-black/50 px-4 py-2 rounded-full">عرض بالحجم الكامل</span>
                                    </a>
                                </div>
                            @else
                                <div class="aspect-[1.6/1] bg-slate-50 rounded-xl border-2 border-dashed border-slate-200 flex flex-col items-center justify-center text-slate-400">
                                    <svg class="w-12 h-12 mb-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
                                    </svg>
                                    <p class="text-xs">لم يتم رفع الصورة</p>
                                </div>
                            @endif
                        </div>
                    </div>
                </x-ui.card>

                <!-- Recent Trips Section -->
                <x-ui.card title="آخر الرحلات">
                    <x-ui.table>
                        <thead>
                            <tr class="text-right border-b border-slate-100">
                                <th class="p-4 text-xs font-bold text-slate-500 uppercase">الرحلة</th>
                                <th class="p-4 text-xs font-bold text-slate-500 uppercase">الراكب</th>
                                <th class="p-4 text-xs font-bold text-slate-500 uppercase">السعر</th>
                                <th class="p-4 text-xs font-bold text-slate-500 uppercase">الحالة</th>
                                <th class="p-4 text-xs font-bold text-slate-500 uppercase">التاريخ</th>
                            </tr>
                        </thead>
                        <tbody>
                            @forelse($recentTrips as $trip)
                                <tr class="border-b border-slate-50 hover:bg-slate-50/50 transition-colors">
                                    <td class="p-4 text-sm font-medium text-slate-900">#{{ $trip->id }}</td>
                                    <td class="p-4 text-sm text-slate-600">{{ $trip->rider->full_name ?? 'غير معروف' }}</td>
                                    <td class="p-4 text-sm font-mono font-bold">{{ number_format($trip->offered_price, 0) }}</td>
                                    <td class="p-4">
                                        @if($trip->status === 'completed')
                                            <span class="text-[10px] px-2 py-0.5 rounded bg-green-100 text-green-700 font-bold uppercase">مكتملة</span>
                                        @elseif($trip->status === 'cancelled')
                                            <span class="text-[10px] px-2 py-0.5 rounded bg-red-100 text-red-700 font-bold uppercase">ملغية</span>
                                        @else
                                            <span class="text-[10px] px-2 py-0.5 rounded bg-blue-100 text-blue-700 font-bold uppercase">{{ $trip->status }}</span>
                                        @endif
                                    </td>
                                    <td class="p-4 text-xs text-slate-500">{{ $trip->created_at->format('M d, H:i') }}</td>
                                </tr>
                            @empty
                                <tr>
                                    <td colspan="5" class="p-8 text-center text-slate-400 text-sm italic">لا توجد رحلات سابقة</td>
                                </tr>
                            @endforelse
                        </tbody>
                    </x-ui.table>
                    @if($recentTrips->isNotEmpty())
                        <div class="p-4 text-center border-t border-slate-50">
                            <a href="{{ route('admin.drivers.trips', $driver) }}" class="text-sm font-bold text-blue-600 hover:text-blue-700">عرض جميع رحلات السائق ({{ $stats['total_trips'] }})</a>
                        </div>
                    @endif
                </x-ui.card>
            </div>
        </div>
    </div>
</x-layouts.admin>
