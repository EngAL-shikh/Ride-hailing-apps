<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    public function up(): void
    {
        // Seed a minimal default SDUI layout so the mobile app can boot even on fresh DBs.
        // Comments in English per repo rules.
        $now = now();

        $payload = [
            'type' => 'column',
            'props' => [
                'padding' => 16,
            ],
            'children' => [
                [
                    'type' => 'text',
                    'props' => [
                        'text' => 'مرحباً بك في مشوار',
                        'style' => 'title',
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
                        'text' => 'اختر من الأسفل: طلب رحلة أو المحفظة',
                    ],
                ],
            ],
        ];

        // Insert only if missing. We keep locale explicit so it matches the app request (ar).
        $exists = DB::table('ui_layouts')
            ->where('key', 'home')
            ->where('platform', 'mobile')
            ->where('locale', 'ar')
            ->exists();

        if (! $exists) {
            DB::table('ui_layouts')->insert([
                'key' => 'home',
                'platform' => 'mobile',
                'locale' => 'ar',
                'version' => 1,
                'payload' => json_encode($payload, JSON_UNESCAPED_UNICODE),
                'is_active' => true,
                'created_at' => $now,
                'updated_at' => $now,
            ]);
        }
    }

    public function down(): void
    {
        DB::table('ui_layouts')
            ->where('key', 'home')
            ->where('platform', 'mobile')
            ->where('locale', 'ar')
            ->delete();
    }
};

