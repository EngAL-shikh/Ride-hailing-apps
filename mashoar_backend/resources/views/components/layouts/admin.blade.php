<!DOCTYPE html>
<html lang="ar" dir="rtl">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta name="csrf-token" content="{{ csrf_token() }}">
    <title>{{ $title ?? 'لوحة التحكم' }} - Mashoar Admin</title>
    
    <!-- Tailwind CSS via CDN -->
    <script src="https://cdn.tailwindcss.com"></script>
    
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
            <nav class="p-4 space-y-2 overflow-y-auto" style="max-height: calc(100vh - 4rem);">
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
                
                <a href="{{ route('admin.sdui.index') }}" class="flex items-center gap-3 px-4 py-2 text-sm font-medium rounded-md {{ request()->routeIs('admin.sdui.*') ? 'bg-slate-100 text-slate-900' : 'text-slate-600 hover:bg-slate-50' }}">
                    <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M7 21a4 4 0 01-4-4V5a2 2 0 012-2h4a2 2 0 012 2v12a4 4 0 01-4 4zm0 0h12a2 2 0 002-2v-4a2 2 0 00-2-2h-2.343M11 7.343l1.657-1.657a2 2 0 012.828 0l2.829 2.829a2 2 0 010 2.828l-8.486 8.485M7 17h.01"/>
                    </svg>
                    <span>SDUI Builder</span>
                </a>
                
                <a href="{{ route('admin.trips.index') }}" class="flex items-center gap-3 px-4 py-2 text-sm font-medium rounded-md {{ request()->routeIs('admin.trips.*') ? 'bg-slate-100 text-slate-900' : 'text-slate-600 hover:bg-slate-50' }}">
                    <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 20l-5.447-2.724A1 1 0 013 16.382V5.618a1 1 0 011.447-.894L9 7m0 13l6-3m-6 3V7m6 10l4.553 2.276A1 1 0 0021 18.382V7.618a1 1 0 00-.553-.894L15 4m0 13V4m0 0L9 7"/>
                    </svg>
                    <span>الرحلات</span>
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
                
                <a href="{{ route('admin.promo-codes.index') }}" class="flex items-center gap-3 px-4 py-2 text-sm font-medium rounded-md {{ request()->routeIs('admin.promo-codes.*') ? 'bg-slate-100 text-slate-900' : 'text-slate-600 hover:bg-slate-50' }}">
                    <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M7 7h.01M7 3h5c.512 0 1.024.195 1.414.586l7 7a2 2 0 010 2.828l-7 7a2 2 0 01-2.828 0l-7-7A1.994 1.994 0 013 12V7a4 4 0 014-4z"/>
                    </svg>
                    <span>أكواد الخصم</span>
                </a>
                
                <a href="{{ route('admin.support.index') }}" class="flex items-center gap-3 px-4 py-2 text-sm font-medium rounded-md {{ request()->routeIs('admin.support.*') ? 'bg-slate-100 text-slate-900' : 'text-slate-600 hover:bg-slate-50' }}">
                    <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M18.364 5.636l-3.536 3.536m0 5.656l3.536 3.536M9.172 9.172L5.636 5.636m3.536 9.192l-3.536 3.536M21 12a9 9 0 11-18 0 9 9 0 0118 0zm-5 0a4 4 0 11-8 0 4 4 0 018 0z"/>
                    </svg>
                    <span>الدعم الفني</span>
                </a>
                
                <a href="{{ route('admin.firebase.index') }}" class="flex items-center gap-3 px-4 py-2 text-sm font-medium rounded-md {{ request()->routeIs('admin.firebase.*') ? 'bg-slate-100 text-slate-900' : 'text-slate-600 hover:bg-slate-50' }}">
                    <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17.657 18.657A8 8 0 016.343 7.343S7 9 9 10c0-2 .5-5 2.986-7C14 5 16.09 5.777 17.656 7.343A7.975 7.975 0 0120 13a7.975 7.975 0 01-2.343 5.657z"/>
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9.879 16.121A3 3 0 1012.015 11L11 14H9c0 .768.293 1.536.879 2.121z"/>
                    </svg>
                    <span>Firebase</span>
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
