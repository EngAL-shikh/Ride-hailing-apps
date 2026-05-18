<?php

namespace Tests\Feature;

use App\Models\UiLayout;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Cache;
use Tests\TestCase;

class UiLayoutTest extends TestCase
{
    use RefreshDatabase;

    public function test_returns_layout_and_uses_cache(): void
    {
        UiLayout::query()->create([
            'key' => 'home',
            'platform' => 'mobile',
            'locale' => 'ar',
            'version' => 1,
            'payload' => [
                'type' => 'column',
                'children' => [
                    ['type' => 'text', 'value' => 'مرحبا'],
                ],
            ],
            'is_active' => true,
        ]);

        $first = $this->getJson('/api/v1/ui/layouts/home?platform=mobile&locale=ar')
            ->assertOk()
            ->json('data');

        $this->assertSame('home', $first['key']);
        $this->assertSame(1, $first['version']);
        $this->assertSame('مرحبا', $first['payload']['children'][0]['value']);

        // Update DB, but cached response should still return version=1 until cache cleared/expired.
        UiLayout::query()->where('key', 'home')->update([
            'version' => 2,
            'payload' => ['type' => 'text', 'value' => 'v2'],
        ]);

        $second = $this->getJson('/api/v1/ui/layouts/home?platform=mobile&locale=ar')
            ->assertOk()
            ->json('data');

        $this->assertSame(1, $second['version']);

        Cache::flush();

        $third = $this->getJson('/api/v1/ui/layouts/home?platform=mobile&locale=ar')
            ->assertOk()
            ->json('data');

        $this->assertSame(2, $third['version']);
    }
}
