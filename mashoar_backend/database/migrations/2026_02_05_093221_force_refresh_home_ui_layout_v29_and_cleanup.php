<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    public function up(): void
    {
        // 1. DELETE any existing 'home' layouts to avoid duplicates or conflicts
        DB::table('ui_layouts')->where('key', 'home')->delete();

        // 2. The EXACT payload from local (version 29)
        $payloadJson = '{"type":"column","children":[{"type":"spacer","props":{"height":352}},{"type":"padding","props":{"left":16,"right":16,"bottom":32},"children":[{"type":"container","props":{"padding":{"all":20},"borderRadius":32,"color":"#1f2f50","border":true,"borderColor":"#374151","borderWidth":1.5,"boxShadow":[{"color":"#00000066","blurRadius":25,"offsetY":12}]},"children":[{"type":"profileHeader","props":[]}]}]},{"type":"padding","props":{"left":16,"right":16,"bottom":24},"children":[{"type":"container","props":{"borderRadius":28,"clipBehavior":"antiAlias","gradient":{"colors":["#10B981","#059669"],"begin":"topLeft","end":"bottomRight"},"boxShadow":[{"color":"#10B98144","blurRadius":20,"offsetY":8}],"action":"route:\/ride-map"},"children":[{"type":"padding","props":{"all":24},"children":[{"type":"row","children":[{"type":"column","props":{"crossAxisAlignment":"start","flex":1},"children":[{"type":"text","props":{"value":"\u0627\u0637\u0644\u0628 \u0639\u0628\u0631 \u0627\u0644\u062e\u0631\u064a\u0637\u0629","style":{"fontSize":22,"fontWeight":"bold","color":"#FFFFFF"}}},{"type":"text","props":{"value":"\u062d\u062f\u062f \u0648\u062c\u0647\u062a\u0643 \u0628\u062f\u0642\u0629 \u0645\u062a\u0646\u0627\u0647\u064a\u0629","style":{"fontSize":14,"color":"#ECFDF5"}}}]},{"type":"icon","props":{"icon":"map","color":"#FFFFFF","size":40}}]}]}]}]},{"type":"padding","props":{"left":16,"right":16,"bottom":32},"children":[{"type":"row","props":{"mainAxisAlignment":"spaceBetween"},"children":[{"type":"flexible","props":{"flex":1},"children":[{"type":"container","props":{"height":100,"borderRadius":24,"color":"#4F46E5","action":"route:\/ride-request"},"children":[{"type":"column","props":{"mainAxisAlignment":"center"},"children":[{"type":"icon","props":{"icon":"ride","color":"#FFFFFF","size":24}},{"type":"spacer","props":{"height":8}},{"type":"text","props":{"value":"\u0637\u0644\u0628 \u0633\u0631\u064a\u0639","style":{"fontSize":13,"color":"#FFFFFF","fontWeight":"w600"}}}]}]}]},{"type":"spacer","props":{"width":12}},{"type":"flexible","props":{"flex":1},"children":[{"type":"container","props":{"height":100,"borderRadius":24,"color":"#1F2937","action":"route:\/my-trips"},"children":[{"type":"column","props":{"mainAxisAlignment":"center"},"children":[{"type":"icon","props":{"icon":"history","color":"#10B981","size":24}},{"type":"spacer","props":{"height":8}},{"type":"text","props":{"value":"\u0631\u062d\u0644\u0627\u062a\u064a","style":{"fontSize":13,"color":"#FFFFFF","fontWeight":"w600"}}}]}]}]},{"type":"spacer","props":{"width":12}},{"type":"flexible","props":{"flex":1},"children":[{"type":"container","props":{"height":100,"borderRadius":24,"color":"#1F2937","action":"route:\/wallet"},"children":[{"type":"column","props":{"mainAxisAlignment":"center"},"children":[{"type":"icon","props":{"icon":"wallet","color":"#A78BFA","size":24}},{"type":"spacer","props":{"height":8}},{"type":"text","props":{"value":"\u0627\u0644\u0645\u062d\u0641\u0638\u0629","style":{"fontSize":13,"color":"#FFFFFF","fontWeight":"w600"}}}]}]}]}]}]},{"type":"padding","props":{"left":16,"right":16,"bottom":16},"children":[{"type":"text","props":{"value":"\u0643\u0628\u0627\u062a\u0646 \u0628\u0627\u0644\u0642\u0631\u0628 \u0645\u0646\u0643","style":{"fontSize":18,"fontWeight":"bold","color":"#FFFFFF"}}}]},{"type":"driversList","props":[]},{"type":"spacer","props":{"height":40}}]}';
        
        $payload = json_decode($payloadJson, true);

        // 3. INSERT as the authoritative record for mobile/ar
        DB::table('ui_layouts')->insert([
            'key' => 'home',
            'platform' => 'mobile',
            'locale' => 'ar',
            'payload' => json_encode($payload, JSON_UNESCAPED_UNICODE),
            'version' => 29,
            'is_active' => true,
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        // 4. PURGE ALL CACHES
        Cache::flush();
    }

    public function down(): void
    {
        // no-op
    }
};
