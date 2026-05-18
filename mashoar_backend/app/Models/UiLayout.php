<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class UiLayout extends Model
{
    protected $fillable = [
        'key',
        'platform',
        'locale',
        'version',
        'payload',
        'is_active',
    ];

    protected $casts = [
        'payload' => 'array',
        'is_active' => 'boolean',
        'version' => 'integer',
    ];
}
