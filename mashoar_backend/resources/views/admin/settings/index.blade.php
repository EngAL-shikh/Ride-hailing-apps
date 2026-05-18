<x-layouts.admin title="الإعدادات">
    <div class="space-y-6">
        <!-- Page Header -->
        <div>
            <h1 class="text-3xl font-bold text-slate-900">إعدادات التطبيق</h1>
            <p class="text-slate-600 mt-1">إدارة جميع إعدادات التطبيق</p>
        </div>

        <!-- Tabs -->
        <div class="border-b border-slate-200">
            <nav class="flex gap-2 overflow-x-auto">
                @foreach($groups as $groupKey => $groupName)
                    <a href="{{ route('admin.settings.index', ['tab' => $groupKey]) }}" 
                       class="px-4 py-2 border-b-2 whitespace-nowrap {{ $tab === $groupKey ? 'border-blue-600 text-blue-600' : 'border-transparent text-slate-600 hover:text-slate-900' }}">
                        {{ $groupName }}
                    </a>
                @endforeach
            </nav>
        </div>

        <!-- Settings Form -->
        <x-ui.card>
            <form action="{{ route('admin.settings.update') }}" method="POST" class="space-y-6">
                @csrf
                @method('PUT')
                
                <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
                    @forelse($settings as $setting)
                        <div>
                            @if($setting->type === 'boolean')
                                <label class="flex items-center gap-3 cursor-pointer">
                                    <input 
                                        type="checkbox" 
                                        name="settings[{{ $setting->key }}]"
                                        value="1"
                                        {{ $setting->value == '1' ? 'checked' : '' }}
                                        class="w-5 h-5 rounded border-slate-300 text-blue-600 focus:ring-blue-500"
                                    />
                                    <div>
                                        <span class="text-sm font-medium text-slate-900">{{ $setting->description }}</span>
                                        <p class="text-xs text-slate-500">{{ $setting->key }}</p>
                                    </div>
                                </label>
                            @else
                                <x-ui.input 
                                    name="settings[{{ $setting->key }}]"
                                    label="{{ $setting->description }}"
                                    type="{{ $setting->type === 'number' ? 'number' : 'text' }}"
                                    value="{{ $setting->value }}"
                                    step="{{ $setting->type === 'number' ? '0.01' : null }}"
                                />
                                <p class="text-xs text-slate-500 mt-1">{{ $setting->key }}</p>
                            @endif
                        </div>
                    @empty
                        <div class="col-span-2 text-center py-8 text-slate-500">
                            لا توجد إعدادات في هذا القسم
                        </div>
                    @endforelse
                </div>

                <div class="flex justify-end gap-3 pt-4 border-t border-slate-200">
                    <x-ui.button type="submit">
                        حفظ التغييرات
                    </x-ui.button>
                </div>
            </form>
        </x-ui.card>

        <!-- Quick Info -->
        <x-ui.card>
            <div class="space-y-2">
                <h3 class="font-semibold text-slate-900">💡 ملاحظات مهمة:</h3>
                <ul class="text-sm text-slate-600 space-y-1 list-disc list-inside">
                    <li>يتم تطبيق التغييرات فوراً على التطبيق</li>
                    <li>تأكد من صحة القيم قبل الحفظ</li>
                    <li>بعض الإعدادات تتطلب إعادة تشغيل التطبيق</li>
                </ul>
            </div>
        </x-ui.card>
    </div>
</x-layouts.admin>
