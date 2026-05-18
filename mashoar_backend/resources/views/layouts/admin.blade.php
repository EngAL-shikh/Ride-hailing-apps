<!DOCTYPE html>
<html lang="ar" dir="rtl">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta name="csrf-token" content="{{ csrf_token() }}">
    <title>{{ $title ?? 'لوحة التحكم' }} - Mashoar Admin</title>
    
    @vite(['resources/css/app.css', 'resources/js/app.js'])
    
    <!-- Alpine.js -->
    <script defer src="https://cdn.jsdelivr.net/npm/alpinejs@3.x.x/dist/cdn.min.js"></script>
    
    <!-- Chart.js -->
    <script src="https://cdn.jsdelivr.net/npm/chart.js@4.4.0/dist/chart.umd.min.js"></script>
    
    <style>
        [x-cloak] { display: none !important; }
    </style>
</head>
<body class="bg-slate-50" x-data="{ sidebarOpen: false }">
    <div class="flex h-screen overflow-hidden">
        <!-- Sidebar -->
        <aside 
            class="fixed inset-y-0 right-0 z-50 w-64 bg-white border-l border-slate-200 transform transition-transform duration-300 lg:translate-x-0"
            :class="sidebarOpen ? 'translate-x-0' : 'translate-x-full lg:translate-x-0'"
        >
            <!-- Logo -->
            <div class="flex items-center justify-center h-16 border-b border-slate-200">
                <h1 class="text-xl font-bold text-slate-900">Mashoar Admin</h1>
            </div>
            
            <!-- Navigation -->
            <nav class="p-4 space-y-2">
                <a href="{{ route('admin.dashboard') }}" class="flex items-center gap-3 px-4 py-2 text-sm font-medium rounded-md {{ request()->routeIs('admin.dashboard') ? 'bg-slate-100 text-slate-900' : 'text-slate-600 hover:bg-slate-50' }}">
                    <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 12l2-2m0 0l7-7 7 7M5 10v10a1 1 0 001 1h3m10-11l2 2m-2-2v10a1 1 0 01-1 1h-3m-6 0a1 1 0 001-1v-4a1 1 0 011-1h2a1 1 0 011 1v4a1 1 0 001 1m-6 0h6"/>
                    </svg>
                    <span>الرئيسية</span>
                </a>
                
                <a href="{{ route('admin.settings.index') }}" class="flex items-center gap-3 px-4 py-2 text-sm font-medium rounded-md {{ request()->routeIs('admin.settings.*') ? 'bg-slate-100 text-slate-900' : 'text-slate-600 hover:bg-slate-50' }}">
                    <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10.325 4.317c.426-1.756 2.924-1.756 3.35 0a1.724 1.724 0 002.573 1.066c1.543-.94 3.31.826 2.37 2.37a1.724 1.724 0 001.065 2.572c1.756.426 1.756 2.924 0 3.35a1.724 1.724 0 00-1.066 2.573c.94 1.543-.826 3.31-2.37 2.37a1.724 1.724 0 00-2.572 1.065c-.426 1.756-2.924 1.756-3.35 0a1.724 1.724 0 00-2.573-1.066c-1.543.94-3.31-.826-2.37-2.37a1.724 1.724 0 00-1.065-2.572c-1.756-.426-1.756-2.924 0-3.35a1.724 1.724 0 001.066-2.573c-.94-1.543.826-3.31 2.37-2.37.996.608 2.296.07 2.572-1.065z"/>
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z"/>
                    </svg>
                    <span>الإعدادات</span>
                </a>
                
                <a href="{{ route('admin.drivers.index') }}" class="flex items-center gap-3 px-4 py-2 text-sm font-medium rounded-md {{ request()->routeIs('admin.drivers.*') ? 'bg-slate-100 text-slate-900' : 'text-slate-600 hover:bg-slate-50' }}">
                    <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"/>
                    </svg>
                    <span>السائقين</span>
                </a>
                
                <a href="{{ route('admin.users.index') }}" class="flex items-center gap-3 px-4 py-2 text-sm font-medium rounded-md {{ request()->routeIs('admin.users.*') ? 'bg-slate-100 text-slate-900' : 'text-slate-600 hover:bg-slate-50' }}">
                    <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4.354a4 4 0 110 5.292M15 21H3v-1a6 6 0 0112 0v1zm0 0h6v-1a6 6 0 00-9-5.197M13 7a4 4 0 11-8 0 4 4 0 018 0z"/>
                    </svg>
                    <span>المستخدمين</span>
                </a>
                
                <a href="{{ route('admin.wallets.index') }}" class="flex items-center gap-3 px-4 py-2 text-sm font-medium rounded-md {{ request()->routeIs('admin.wallets.*') ? 'bg-slate-100 text-slate-900' : 'text-slate-600 hover:bg-slate-50' }}">
                    <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 10h18M7 15h1m4 0h1m-7 4h12a3 3 0 003-3V8a3 3 0 00-3-3H6a3 3 0 00-3 3v8a3 3 0 003 3z"/>
                    </svg>
                    <span>المحافظ</span>
                </a>
                
                <a href="{{ route('admin.marketing.index') }}" class="flex items-center gap-3 px-4 py-2 text-sm font-medium rounded-md {{ request()->routeIs('admin.marketing.*') ? 'bg-slate-100 text-slate-900' : 'text-slate-600 hover:bg-slate-50' }}">
                    <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 17h5l-1.405-1.405A2.032 2.032 0 0118 14.158V11a6.002 6.002 0 00-4-5.659V5a2 2 0 10-4 0v.341C7.67 6.165 6 8.388 6 11v3.159c0 .538-.214 1.055-.595 1.436L4 17h5m6 0v1a3 3 0 11-6 0v-1m6 0H9"/>
                    </svg>
                    <span>التسويق</span>
                </a>
            </nav>
        </aside>
        
        <!-- Main Content -->
        <div class="flex-1 flex flex-col overflow-hidden lg:mr-64">
            <!-- Top Bar -->
            <header class="bg-white border-b border-slate-200 h-16 flex items-center justify-between px-6">
                <button 
                    @click="sidebarOpen = !sidebarOpen"
                    class="lg:hidden text-slate-600 hover:text-slate-900"
                >
                    <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 6h16M4 12h16M4 18h16"/>
                    </svg>
                </button>
                
                <div class="flex items-center gap-4">
                    <span class="text-sm text-slate-600">مرحباً، Admin</span>
                    <form method="POST" action="{{ route('logout') }}">
                        @csrf
                        <x-ui.button type="submit" variant="outline" size="sm">
                            تسجيل الخروج
                        </x-ui.button>
                    </form>
                </div>
            </header>
            
            <!-- Page Content -->
            <main class="flex-1 overflow-y-auto p-6">
                @if(session('success'))
                    <div class="mb-4 p-4 bg-green-50 border border-green-200 rounded-lg text-green-800">
                        {{ session('success') }}
                    </div>
                @endif
                
                @if(session('error'))
                    <div class="mb-4 p-4 bg-red-50 border border-red-200 rounded-lg text-red-800">
                        {{ session('error') }}
                    </div>
                @endif
                
                {{ $slot }}
            </main>
        </div>
    </div>
    
    <!-- Sidebar Overlay (Mobile) -->
    <div 
        x-show="sidebarOpen" 
        @click="sidebarOpen = false"
        x-cloak
        class="fixed inset-0 bg-black/50 z-40 lg:hidden"
    ></div>
</body>
</html>
