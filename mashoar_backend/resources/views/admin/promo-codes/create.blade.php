<x-layouts.admin title="إنشاء كود خصم">
    <div class="max-w-2xl">
        <h1 class="text-3xl font-bold text-slate-900 mb-6">إنشاء كود خصم جديد</h1>

        <x-ui.card>
            <form action="{{ route('admin.promo-codes.store') }}" method="POST" class="space-y-6">
                @csrf

                <x-ui.input name="code" label="رمز الكود" required placeholder="SUMMER2026" />

                <div>
                    <label class="block text-sm font-medium mb-2">نوع الخصم</label>
                    <select name="type" required class="w-full px-3 py-2 border border-slate-300 rounded-lg">
                        <option value="percentage">نسبة مئوية</option>
                        <option value="fixed">مبلغ ثابت</option>
                        <option value="free_ride">رحلة مجانية</option>
                    </select>
                </div>

                <x-ui.input name="value" label="القيمة" type="number" step="0.01" required />
                <x-ui.input name="min_trip_amount" label="الحد الأدنى لقيمة الرحلة" type="number" step="0.01" />
                <x-ui.input name="max_discount" label="الحد الأقصى للخصم (للنسبة المئوية)" type="number" step="0.01" />
                
                <div class="grid grid-cols-2 gap-4">
                    <x-ui.input name="usage_limit_total" label="الحد الأقصى للاستخدام الكلي" type="number" />
                    <x-ui.input name="usage_limit_per_user" label="الحد الأقصى لكل مستخدم" type="number" value="1" required />
                </div>

                <div class="grid grid-cols-2 gap-4">
                    <x-ui.input name="valid_from" label="صالح من" type="datetime-local" />
                    <x-ui.input name="valid_until" label="صالح حتى" type="datetime-local" />
                </div>

                <label class="flex items-center gap-2">
                    <input type="checkbox" name="new_users_only" class="rounded border-slate-300">
                    <span class="text-sm">للمستخدمين الجدد فقط</span>
                </label>

                <x-ui.input name="description" label="الوصف" placeholder="خصم الصيف..." />

                <div class="flex gap-3">
                    <x-ui.button type="submit">إنشاء الكود</x-ui.button>
                    <a href="{{ route('admin.promo-codes.index') }}">
                        <x-ui.button type="button" variant="outline">إلغاء</x-ui.button>
                    </a>
                </div>
            </form>
        </x-ui.card>
    </div>
</x-layouts.admin>
