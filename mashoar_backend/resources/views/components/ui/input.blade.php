@props([
    'label' => null,
    'error' => null,
    'type' => 'text',
    'required' => false,
])

<div class="space-y-2">
    @if($label)
        <label for="{{ $attributes->get('id') ?? $attributes->get('name') }}" class="text-sm font-medium leading-none peer-disabled:cursor-not-allowed peer-disabled:opacity-70">
            {{ $label }}
            @if($required)
                <span class="text-red-500">*</span>
            @endif
        </label>
    @endif
    
    <input 
        type="{{ $type }}"
        {{ $attributes->except(['label', 'error'])->merge(['class' => 'flex h-10 w-full rounded-md border border-slate-300 bg-white px-3 py-2 text-sm ring-offset-white file:border-0 file:bg-transparent file:text-sm file:font-medium placeholder:text-slate-500 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-slate-400 focus-visible:ring-offset-2 disabled:cursor-not-allowed disabled:opacity-50']) }}
    />
    
    @if($error)
        <p class="text-sm text-red-600">{{ $error }}</p>
    @endif
</div>
