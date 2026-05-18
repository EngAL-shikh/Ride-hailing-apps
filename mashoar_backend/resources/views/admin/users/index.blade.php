<x-layouts.admin title="إدارة المستخدمين">
    <div class="space-y-6">
        <!-- Page Header -->
        <div class="flex items-center justify-between">
            <div>
                <h1 class="text-3xl font-bold text-slate-900">إدارة المستخدمين</h1>
                <p class="text-slate-600 mt-1">عرض وإدارة المستخدمين المسجلين</p>
            </div>
        </div>

        <!-- Search -->
        <x-ui.card>
            <form action="{{ route('admin.users.index') }}" method="GET" class="flex gap-2">
                <input 
                    type="text" 
                    name="search" 
                    value="{{ $search ?? '' }}"
                    placeholder="البحث بالاسم أو الهاتف أو البريد..."
                    class="flex-1 h-10 rounded-md border border-slate-300 px-3 py-2"
                />
                <x-ui.button type="submit">
                    <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z"/>
                    </svg>
                </x-ui.button>
            </form>
        </x-ui.card>

        <!-- Users Table -->
        <x-ui.card>
            <x-ui.table>
                <thead class="border-b border-slate-200">
                    <tr>
                        <th class="text-right p-4 font-medium text-slate-600">الاسم</th>
                        <th class="text-right p-4 font-medium text-slate-600">رقم الهاتف</th>
                        <th class="text-right p-4 font-medium text-slate-600">البريد الإلكتروني</th>
                        <th class="text-right p-4 font-medium text-slate-600">النوع</th>
                        <th class="text-right p-4 font-medium text-slate-600">التاريخ</th>
                        <th class="text-right p-4 font-medium text-slate-600">الإجراءات</th>
                    </tr>
                </thead>
                <tbody>
                    @forelse($users as $user)
                        <tr class="border-b border-slate-100">
                            <td class="p-4">{{ $user->name }}</td>
                            <td class="p-4 font-mono">{{ $user->phone }}</td>
                            <td class="p-4">{{ $user->email ?? 'غير محدد' }}</td>
                            <td class="p-4">
                                <x-ui.badge :variant="$user->user_type === 'driver' ? 'info' : 'default'">
                                    {{ $user->user_type === 'driver' ? 'سائق' : 'راكب' }}
                                </x-ui.badge>
                            </td>
                            <td class="p-4 text-sm text-slate-600">{{ $user->created_at->diffForHumans() }}</td>
                            <td class="p-4">
                                <div class="flex gap-2">
                                    <a href="{{ route('admin.users.edit', $user) }}">
                                        <x-ui.button variant="outline" size="sm">
                                            تعديل
                                        </x-ui.button>
                                    </a>
                                    
                                    <form action="{{ route('admin.users.destroy', $user) }}" method="POST" onsubmit="return confirm('هل أنت متأكد؟')">
                                        @csrf
                                        @method('DELETE')
                                        <x-ui.button type="submit" variant="destructive" size="sm">
                                            حذف
                                        </x-ui.button>
                                    </form>
                                </div>
                            </td>
                        </tr>
                    @empty
                        <tr>
                            <td colspan="6" class="p-8 text-center text-slate-500">لا يوجد مستخدمين</td>
                        </tr>
                    @endforelse
                </tbody>
            </x-ui.table>

            @if($users->hasPages())
                <div class="p-4 border-t border-slate-200">
                    {{ $users->appends(['search' => $search])->links() }}
                </div>
            @endif
        </x-ui.card>
    </div>
</x-layouts.admin>
