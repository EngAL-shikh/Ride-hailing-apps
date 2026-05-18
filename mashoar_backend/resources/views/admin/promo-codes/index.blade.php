<x-layouts.admin title="أكواد الخصم">
    <div class="space-y-6">
        <div class="flex items-center justify-between">
            <div>
                <h1 class="text-3xl font-bold text-slate-900">أكواد الخصم</h1>
                <p class="text-slate-600 mt-1">إدارة أكواد الخصم والعروض الترويجية</p>
            </div>
            <a href="{{ route('admin.promo-codes.create') }}">
                <x-ui.button>+ إنشاء كود جديد</x-ui.button>
            </a>
        </div>

        <x-ui.card>
            <x-ui.table>
                <thead class="border-b border-slate-200">
                    <tr>
                        <th class="text-right p-4 font-medium text-slate-600">الكود</th>
                        <th class="text-right p-4 font-medium text-slate-600">النوع</th>
                        <th class="text-right p-4 font-medium text-slate-600">القيمة</th>
                        <th class="text-right p-4 font-medium text-slate-600">الاستخدام</th>
                        <th class="text-right p-4 font-medium text-slate-600">الصلاحية</th>
                        <th class="text-right p-4 font-medium text-slate-600">الحالة</th>
                        <th class="text-right p-4 font-medium text-slate-600">الإجراءات</th>
                    </tr>
                </thead>
                <tbody>
                    @forelse($promoCodes as $promo)
                        <tr class="border-b border-slate-100">
                            <td class="p-4 font-mono font-bold">{{ $promo->code }}</td>
                            <td class="p-4">
                                @if($promo->type === 'percentage')
                                    نسبة مئوية
                                @elseif($promo->type === 'fixed')
                                    مبلغ ثابت
                                @else
                                    رحلة مجانية
                                @endif
                            </td>
                            <td class="p-4">
                                @if($promo->type === 'percentage')
                                    {{ $promo->value }}%
                                @else
                                    {{ number_format($promo->value) }} ر.ي
                                @endif
                            </td>
                            <td class="p-4">
                                {{ $promo->usages_count }} / {{ $promo->usage_limit_total ?? '∞' }}
                            </td>
                            <td class="p-4 text-sm">
                                @if($promo->valid_until)
                                    {{ $promo->valid_until->format('Y-m-d') }}
                                @else
                                    دائم
                                @endif
                            </td>
                            <td class="p-4">
                                <form action="{{ route('admin.promo-codes.toggle', $promo) }}" method="POST" class="inline">
                                    @csrf
                                    <button type="submit">
                                        <x-ui.badge :variant="$promo->is_active ? 'success' : 'danger'">
                                            {{ $promo->is_active ? 'نشط' : 'معطل' }}
                                        </x-ui.badge>
                                    </button>
                                </form>
                            </td>
                            <td class="p-4">
                                <div class="flex gap-2">
                                    <a href="{{ route('admin.promo-codes.edit', $promo) }}">
                                        <x-ui.button variant="outline" size="sm">تعديل</x-ui.button>
                                    </a>
                                    <form action="{{ route('admin.promo-codes.destroy', $promo) }}" method="POST" class="inline">
                                        @csrf
                                        @method('DELETE')
                                        <x-ui.button type="submit" variant="destructive" size="sm" onclick="return confirm('هل أنت متأكد؟')">
                                            حذف
                                        </x-ui.button>
                                    </form>
                                </div>
                            </td>
                        </tr>
                    @empty
                        <tr>
                            <td colspan="7" class="p-8 text-center text-slate-500">لا توجد أكواد خصم</td>
                        </tr>
                    @endforelse
                </tbody>
            </x-ui.table>

            @if($promoCodes->hasPages())
                <div class="p-4 border-t border-slate-200">
                    {{ $promoCodes->links() }}
                </div>
            @endif
        </x-ui.card>
    </div>
</x-layouts.admin>
