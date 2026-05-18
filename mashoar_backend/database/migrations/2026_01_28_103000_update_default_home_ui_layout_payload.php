<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    public function up(): void
    {
        // Update the previously seeded layout to match the Flutter SDUI renderer schema.
        // Text widget expects props.value and style expects a map (not a string).
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
                            'props' => [
                                'height' => 12,
                            ],
                        ],
                        [
                            'type' => 'text',
                            'props' => [
                                'value' => 'اختر من الأسفل: طلب رحلة أو المحفظة',
                                'textAlign' => 'right',
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
                'version' => 2,
                'updated_at' => $now,
            ]);

        // Clear SDUI cache for this layout key so the app receives the updated payload immediately.
        Cache::forget('ui_layout:mobile:ar:home');
    }

    public function down(): void
    {
        // No rollback needed for payload change in this iteration.
    }
};

