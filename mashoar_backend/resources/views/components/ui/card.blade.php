@props(['header' => null, 'footer' => null])

<div {{ $attributes->merge(['class' => 'rounded-xl border border-slate-200 bg-white text-slate-950 shadow-sm']) }}>
    @if($header)
        <div class="flex flex-col space-y-1.5 p-6 border-b border-slate-200">
            {{ $header }}
        </div>
    @endif
    
    <div class="p-6">
        {{ $slot }}
    </div>
    
    @if($footer)
        <div class="flex items-center p-6 pt-0 border-t border-slate-200">
            {{ $footer }}
        </div>
    @endif
</div>
