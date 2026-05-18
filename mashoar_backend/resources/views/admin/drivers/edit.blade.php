<x-layouts.admin title="تعديل بيانات السائق: {{ $driver->full_name }}">
    <div class="max-w-2xl mx-auto">
        <x-ui.card title="تعديل بيانات السائق">
            <form action="{{ route('admin.drivers.update', $driver) }}" method="POST" class="p-6 space-y-4">
                @csrf
                @method('PUT')

                <x-ui.input 
                    name="full_name" 
                    label="الاسم الكامل" 
                    value="{{ old('full_name', $driver->full_name) }}" 
                    required 
                />

                <x-ui.input 
                    name="phone" 
                    label="رقم الهاتف" 
                    value="{{ old('phone', $driver->user->phone) }}" 
                    required 
                />

                <x-ui.input 
                    name="bike_plate" 
                    label="رقم اللوحة" 
                    value="{{ old('bike_plate', $driver->bike_plate) }}" 
                    required 
                />

                <div class="space-y-1">
                    <label class="text-sm font-medium text-slate-700">التقييم (0-5)</label>
                    <input 
                        type="number" 
                        name="rating" 
                        step="0.1" 
                        min="0" 
                        max="5" 
                        value="{{ old('rating', $driver->rating) }}" 
                        class="w-full rounded-lg border-slate-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
                    />
                </div>

                <div class="grid grid-cols-2 gap-4">
                    <div class="space-y-1">
                        <label class="text-sm font-medium text-slate-700">حالة التحقق</label>
                        <select name="verification_status" class="w-full rounded-lg border-slate-300 shadow-sm focus:border-blue-500 focus:ring-blue-500">
                            <option value="pending" {{ old('verification_status', $driver->verification_status) === 'pending' ? 'selected' : '' }}>بانتظار التحقق</option>
                            <option value="approved" {{ old('verification_status', $driver->verification_status) === 'approved' ? 'selected' : '' }}>مقبول</option>
                            <option value="rejected" {{ old('verification_status', $driver->verification_status) === 'rejected' ? 'selected' : '' }}>مرفوض</option>
                        </select>
                    </div>

                    <div class="space-y-1">
                        <label class="text-sm font-medium text-slate-700">حالة الحساب</label>
                        <select name="is_active" class="w-full rounded-lg border-slate-300 shadow-sm focus:border-blue-500 focus:ring-blue-500">
                            <option value="1" {{ old('is_active', $driver->user->is_active) ? 'selected' : '' }}>نشط</option>
                            <option value="0" {{ old('is_active', $driver->user->is_active) ? '' : 'selected' }}>معطل</option>
                        </select>
                    </div>
                </div>

                <div class="flex items-center gap-4 pt-4 border-t border-slate-100">
                    <x-ui.button type="submit">حفظ التغييرات</x-ui.button>
                    <a href="{{ route('admin.drivers.show', $driver) }}" class="text-sm text-slate-600 hover:text-slate-900">إلغاء</a>
                </div>
            </form>
        </x-ui.card>
    </div>
</x-layouts.admin>
