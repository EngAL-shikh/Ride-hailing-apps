<x-layouts.admin title="تعديل مستخدم">
    <div class="max-w-2xl space-y-6">
        <!-- Page Header -->
        <div>
            <h1 class="text-3xl font-bold text-slate-900">تعديل مستخدم</h1>
            <p class="text-slate-600 mt-1">تعديل بيانات: {{ $user->name }}</p>
        </div>

        <!-- Edit Form -->
        <x-ui.card>
            <form action="{{ route('admin.users.update', $user) }}" method="POST" class="space-y-4">
                @csrf
                @method('PUT')
                
                <x-ui.input 
                    name="name" 
                    label="الاسم"
                    :value="$user->name"
                    required
                />

                <x-ui.input 
                    name="email" 
                    type="email"
                    label="البريد الإلكتروني"
                    :value="$user->email"
                />

                <div>
                    <label class="flex items-center gap-2">
                        <input 
                            type="checkbox" 
                            name="is_banned" 
                            value="1"
                            {{ $user->is_banned ? 'checked' : '' }}
                            class="rounded border-slate-300"
                        />
                        <span class="text-sm font-medium text-slate-700">حظر المستخدم</span>
                    </label>
                    <p class="text-sm text-slate-500 mt-1">المستخدم المحظور لن يتمكن من استخدام التطبيق</p>
                </div>

                <div class="flex gap-2">
                    <x-ui.button type="submit">
                        حفظ التغييرات
                    </x-ui.button>
                    
                    <a href="{{ route('admin.users.index') }}">
                        <x-ui.button type="button" variant="outline">
                            إلغاء
                        </x-ui.button>
                    </a>
                </div>
            </form>
        </x-ui.card>
    </div>
</x-layouts.admin>
