@props([
    'variant' => 'default',
    'size' => 'default',
    'type' => 'button',
])

@php
$variants = [
    'default' => 'bg-slate-900 text-white hover:bg-slate-800',
    'destructive' => 'bg-red-600 text-white hover:bg-red-700',
    'outline' => 'border border-slate-300 bg-white hover:bg-slate-100',
    'ghost' => 'hover:bg-slate-100',
    'link' => 'text-slate-900 underline-offset-4 hover:underline',
];

$sizes = [
    'default' => 'h-10 px-4 py-2',
    'sm' => 'h-9 px-3 text-sm',
    'lg' => 'h-11 px-8',
    'icon' => 'h-10 w-10',
];
@endphp

<button 
    type="{{ $type }}"
    {{ $attributes->merge(['class' => "inline-flex items-center justify-center rounded-md text-sm font-medium transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-slate-400 disabled:pointer-events-none disabled:opacity-50 {$variants[$variant]} {$sizes[$size]}"]) }}
>
    {{ $slot }}
</button>
