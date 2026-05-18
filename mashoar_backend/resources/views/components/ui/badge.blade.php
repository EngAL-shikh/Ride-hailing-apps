@props([
    'variant' => 'default',
])

@php
$variants = [
    'default' => 'bg-slate-100 text-slate-900 border-slate-200',
    'success' => 'bg-green-100 text-green-900 border-green-200',
    'warning' => 'bg-yellow-100 text-yellow-900 border-yellow-200',
    'danger' => 'bg-red-100 text-red-900 border-red-200',
    'info' => 'bg-blue-100 text-blue-900 border-blue-200',
];
@endphp

<span {{ $attributes->merge(['class' => "inline-flex items-center rounded-full border px-2.5 py-0.5 text-xs font-semibold transition-colors {$variants[$variant]}"]) }}>
    {{ $slot }}
</span>
