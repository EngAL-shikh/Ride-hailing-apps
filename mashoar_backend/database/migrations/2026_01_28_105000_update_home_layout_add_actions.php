<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    public function up(): void
    {
        // Add actionable buttons to the seeded home SDUI layout (mobile/ar).
        $now = now();

        $payload = [
            'type' => 'padding',
            'props' => [
                'all' => 16,
            ],
            'children' => [
                [
                    'type' => 'column',
                    'props' => [
                        'crossAxisAlignment' => 'stretch',
                        'mainAxisAlignment' => 'start',
                    ],
                    'children' => [
                        [
                            'type' => 'text',
                            'props' => [
                                'value' => 'مرحباً بك في مشوار',
                                'textAlign' => 'right',
                                'style' => [
                                    'fontSize' => 20,
                                    'fontWeight' => 'w700',
                                ],
                            ],
                        ],
                        [
                            'type' => 'spacer',
                            'props' => ['height' => 12],
                        ],
                        [
                            'type' => 'text',
                            'props' => [
                                'value' => 'اختر خدمة:',
                                'textAlign' => 'right',
                            ],
                        ],
                        [
                            'type' => 'spacer',
                            'props' => ['height' => 12],
                        ],
                        [
                            'type' => 'button',
                            'props' => [
                                'label' => 'طلب رحلة',
                                'route' => '/ride-request',
                            ],
                        ],
                        [
                            'type' => 'spacer',
                            'props' => ['height' => 12],
                        ],
                        [
                            'type' => 'button',
                            'props' => [
                                'label' => 'المحفظة',
                                'route' => '/wallet',
                            ],
                        ],
                    ],
                ],
            ],
        ];

        DB::table('ui_layouts')
            ->where('key', 'home')
            ->where('platform', 'mobile')
            ->where('locale', 'ar')
            ->update([
                'payload' => json_encode($payload, JSON_UNESCAPED_UNICODE),
                'version' => 3,
                'updated_at' => $now,
            ]);

        Cache::forget('ui_layout:mobile:ar:home');
    }

    public function down(): void
    {
        // no-op
    }
};

