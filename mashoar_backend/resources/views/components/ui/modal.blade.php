@props(['id', 'title' => null])

<div 
    x-data="{ open: false }"
    x-show="open"
    @open-modal.window="if ($event.detail === '{{ $id }}') open = true"
    @close-modal.window="if ($event.detail === '{{ $id }}') open = false"
    @keydown.escape.window="open = false"
    x-cloak
    class="fixed inset-0 z-50 flex items-center justify-center bg-black/50"
    style="display: none;"
>
    <div 
        @click.away="open = false"
        class="relative bg-white rounded-lg shadow-lg max-w-lg w-full mx-4 max-h-[90vh] overflow-y-auto"
    >
        @if($title)
            <div class="flex items-center justify-between p-6 border-b border-slate-200">
                <h3 class="text-lg font-semibold">{{ $title }}</h3>
                <button 
                    @click="open = false"
                    class="text-slate-400 hover:text-slate-600 transition"
                >
                    <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"/>
                    </svg>
                </button>
            </div>
        @endif
        
        <div class="p-6">
            {{ $slot }}
        </div>
    </div>
</div>
