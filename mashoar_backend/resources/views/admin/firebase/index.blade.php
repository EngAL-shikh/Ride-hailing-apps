<x-layouts.admin title="Firebase Configuration">
    <div class="space-y-6">
        <div>
            <h1 class="text-3xl font-bold text-slate-900">إعدادات Firebase</h1>
            <p class="text-slate-600 mt-1">إدارة Firebase Cloud Messaging</p>
        </div>

        <div class="grid grid-cols-1 lg:grid-cols-2 gap-6">
            <!-- FCM Settings -->
            <x-ui.card>
                <h2 class="text-lg font-semibold mb-4">إعدادات FCM</h2>
                <div class="space-y-4">
                    <div>
                        <label class="block text-sm font-medium mb-1">Server Key</label>
                        <input type="text" value="{{ $fcmSettings['fcm_server_key'] }}" readonly 
                               class="w-full px-3 py-2 border border-slate-300 rounded-lg bg-slate-50">
                        <p class="text-xs text-slate-500 mt-1">يتم تعديله من صفحة الإعدادات → الإشعارات</p>
                    </div>
                    <div>
                        <label class="block text-sm font-medium mb-1">Project ID</label>
                        <input type="text" value="{{ $fcmSettings['fcm_project_id'] }}" readonly 
                               class="w-full px-3 py-2 border border-slate-300 rounded-lg bg-slate-50">
                    </div>
                    <div>
                        <label class="block text-sm font-medium mb-1">Sender ID</label>
                        <input type="text" value="{{ $fcmSettings['fcm_sender_id'] }}" readonly 
                               class="w-full px-3 py-2 border border-slate-300 rounded-lg bg-slate-50">
                    </div>
                    <a href="{{ route('admin.settings.index', ['tab' => 'notifications']) }}">
                        <x-ui.button variant="outline">تعديل الإعدادات</x-ui.button>
                    </a>
                </div>
            </x-ui.card>

            <!-- Test Notification -->
            <x-ui.card>
                <h2 class="text-lg font-semibold mb-4">اختبار الإشعارات</h2>
                <form action="{{ route('admin.firebase.test') }}" method="POST" class="space-y-4">
                    @csrf
                    
                    <x-ui.input 
                        name="token" 
                        label="FCM Token" 
                        required 
                        placeholder="Device FCM Token"
                    />
                    
                    <x-ui.input 
                        name="title" 
                        label="العنوان" 
                        required 
                        placeholder="عنوان الإشعار"
                    />
                    
                    <div>
                        <label class="block text-sm font-medium mb-1">الرسالة</label>
                        <textarea 
                            name="body" 
                            required 
                            rows="3"
                            placeholder="نص الإشعار"
                            class="w-full px-3 py-2 border border-slate-300 rounded-lg"
                        ></textarea>
                    </div>
                    
                    <x-ui.button type="submit">إرسال إشعار تجريبي</x-ui.button>
                </form>

                <div class="mt-6 p-4 bg-blue-50 border border-blue-200 rounded-lg">
                    <h3 class="font-semibold text-sm mb-2">💡 كيفية الحصول على FCM Token:</h3>
                    <ol class="text-sm text-slate-600 space-y-1 list-decimal list-inside">
                        <li>افتح التطبيق على الجهاز</li>
                        <li>انسخ الـ FCM Token من إعدادات التطبيق</li>
                        <li>الصقه في الحقل أعلاه</li>
                    </ol>
                </div>
            </x-ui.card>
        </div>

        <!-- Documentation -->
        <x-ui.card>
            <h2 class="text-lg font-semibold mb-4">📚 التوثيق</h2>
            <div class="space-y-3 text-sm">
                <div>
                    <h3 class="font-semibold">الحصول على Server Key:</h3>
                    <ol class="list-decimal list-inside text-slate-600 space-y-1 mt-1">
                        <li>افتح <a href="https://console.firebase.google.com" target="_blank" class="text-blue-600 hover:underline">Firebase Console</a></li>
                        <li>اختر المشروع</li>
                        <li>Project Settings → Cloud Messaging</li>
                        <li>انسخ Server Key</li>
                    </ol>
                </div>
                <div>
                    <h3 class="font-semibold">تفعيل FCM في التطبيق:</h3>
                    <ol class="list-decimal list-inside text-slate-600 space-y-1 mt-1">
                        <li>تأكد من إضافة google-services.json للتطبيق</li>
                        <li>تفعيل Firebase Messaging في pubspec.yaml</li>
                        <li>طلب أذونات الإشعارات من المستخدم</li>
                    </ol>
                </div>
            </div>
        </x-ui.card>
    </div>
</x-layouts.admin>
