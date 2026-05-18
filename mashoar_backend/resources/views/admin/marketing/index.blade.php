<x-layouts.admin title="التسويق">
    <div class="space-y-6">
        <!-- Page Header -->
        <div>
            <h1 class="text-3xl font-bold text-slate-900">مركز التسويق</h1>
            <p class="text-slate-600 mt-1">إرسال إشعارات للمستخدمين</p>
        </div>

        <!-- Send Notification Form -->
        <x-ui.card>
            <x-slot name="header">
                <h3 class="text-lg font-semibold">إرسال إشعار جديد</h3>
            </x-slot>

            <form action="{{ route('admin.marketing.send') }}" method="POST" class="space-y-4">
                @csrf
                
                <x-ui.input 
                    name="title" 
                    label="عنوان الإشعار"
                    placeholder="مثال: عرض خاص"
                    required
                />

                <div>
                    <label for="body" class="block text-sm font-medium text-slate-700 mb-2">نص الإشعار *</label>
                    <textarea 
                        name="body" 
                        id="body"
                        rows="4"
                        class="w-full rounded-md border border-slate-300 px-3 py-2"
                        placeholder="اكتب نص الإشعار هنا..."
                        required
                    ></textarea>
                </div>

                <div>
                    <label class="block text-sm font-medium text-slate-700 mb-2">الجمهور المستهدف *</label>
                    <div class="space-y-2">
                        <label class="flex items-center p-3 border border-slate-200 rounded-lg hover:bg-slate-50 cursor-pointer">
                            <input type="radio" name="audience" value="all" checked class="ml-2">
                            <div>
                                <p class="font-medium">الجميع</p>
                                <p class="text-sm text-slate-600">إرسال لجميع المستخدمين (سائقين وركاب)</p>
                            </div>
                        </label>
                        
                        <label class="flex items-center p-3 border border-slate-200 rounded-lg hover:bg-slate-50 cursor-pointer">
                            <input type="radio" name="audience" value="drivers" class="ml-2">
                            <div>
                                <p class="font-medium">السائقين فقط</p>
                                <p class="text-sm text-slate-600">إرسال للسائقين المسجلين</p>
                            </div>
                        </label>
                        
                        <label class="flex items-center p-3 border border-slate-200 rounded-lg hover:bg-slate-50 cursor-pointer">
                            <input type="radio" name="audience" value="riders" class="ml-2">
                            <div>
                                <p class="font-medium">الركاب فقط</p>
                                <p class="text-sm text-slate-600">إرسال للركاب المسجلين</p>
                            </div>
                        </label>
                    </div>
                </div>

                <div class="flex justify-end gap-2">
                    <x-ui.button type="submit">
                        <svg class="w-5 h-5 ml-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 19l9 2-9-18-9 18 9-2zm0 0v-8"/>
                        </svg>
                        إرسال الإشعار
                    </x-ui.button>
                </div>
            </form>
        </x-ui.card>

        <!-- Info Card -->
        <x-ui.card>
            <div class="flex items-start gap-4">
                <div class="p-3 bg-blue-100 rounded-lg">
                    <svg class="w-6 h-6 text-blue-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"/>
                    </svg>
                </div>
                <div>
                    <h4 class="font-semibold text-slate-900">ملاحظات مهمة</h4>
                    <ul class="mt-2 space-y-1 text-sm text-slate-600">
                        <li>• سيتم إرسال الإشعار فقط للمستخدمين الذين لديهم FCM Token</li>
                        <li>• يمكن أن يستغرق الإرسال بضع دقائق حسب عدد المستخدمين</li>
                        <li>• تأكد من صحة النص قبل الإرسال - لا يمكن التراجع</li>
                    </ul>
                </div>
            </div>
        </x-ui.card>
    </div>
</x-layouts.admin>
