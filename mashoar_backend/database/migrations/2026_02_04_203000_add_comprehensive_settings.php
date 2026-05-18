<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    public function up(): void
    {
        // Add comprehensive settings
        $settings = [
            // Pricing Engine
            ['key' => 'base_fare', 'value' => '500', 'type' => 'number', 'group' => 'pricing', 'description' => 'السعر الأساسي (ر.ي)'],
            ['key' => 'per_km_rate', 'value' => '50', 'type' => 'number', 'group' => 'pricing', 'description' => 'سعر الكيلومتر (ر.ي)'],
            ['key' => 'per_minute_rate', 'value' => '10', 'type' => 'number', 'group' => 'pricing', 'description' => 'سعر الدقيقة (ر.ي)'],
            ['key' => 'surge_multiplier', 'value' => '1.5', 'type' => 'number', 'group' => 'pricing', 'description' => 'معامل الزيادة في أوقات الذروة'],
            ['key' => 'cancellation_fee_rider', 'value' => '100', 'type' => 'number', 'group' => 'pricing', 'description' => 'رسوم إلغاء الراكب (ر.ي)'],
            ['key' => 'cancellation_fee_driver', 'value' => '200', 'type' => 'number', 'group' => 'pricing', 'description' => 'رسوم إلغاء السائق (ر.ي)'],
            ['key' => 'night_charge_percentage', 'value' => '20', 'type' => 'number', 'group' => 'pricing', 'description' => 'نسبة الزيادة الليلية (%)'],
            
            // Driver Settings
            ['key' => 'max_concurrent_trips', 'value' => '1', 'type' => 'number', 'group' => 'driver', 'description' => 'الحد الأقصى للرحلات المتزامنة'],
            ['key' => 'min_rating_to_stay_active', 'value' => '3.0', 'type' => 'number', 'group' => 'driver', 'description' => 'الحد الأدنى للتقييم للبقاء نشطاً'],
            ['key' => 'auto_assign_timeout', 'value' => '30', 'type' => 'number', 'group' => 'driver', 'description' => 'مهلة التعيين التلقائي (ثانية)'],
            
            // Rider Settings
            ['key' => 'max_waiting_time', 'value' => '15', 'type' => 'number', 'group' => 'rider', 'description' => 'الحد الأقصى لوقت الانتظار (دقيقة)'],
            ['key' => 'free_cancellation_window', 'value' => '2', 'type' => 'number', 'group' => 'rider', 'description' => 'نافذة الإلغاء المجاني (دقيقة)'],
            ['key' => 'max_trip_distance', 'value' => '100', 'type' => 'number', 'group' => 'rider', 'description' => 'الحد الأقصى لمسافة الرحلة (كم)'],
            
            // Payment Settings
            ['key' => 'cash_enabled', 'value' => '1', 'type' => 'boolean', 'group' => 'payment', 'description' => 'تفعيل الدفع نقداً'],
            ['key' => 'wallet_enabled', 'value' => '1', 'type' => 'boolean', 'group' => 'payment', 'description' => 'تفعيل المحفظة'],
            ['key' => 'card_payment_enabled', 'value' => '0', 'type' => 'boolean', 'group' => 'payment', 'description' => 'تفعيل الدفع بالبطاقة'],
            ['key' => 'currency_symbol', 'value' => 'ر.ي', 'type' => 'string', 'group' => 'payment', 'description' => 'رمز العملة'],
            ['key' => 'tax_rate', 'value' => '0', 'type' => 'number', 'group' => 'payment', 'description' => 'نسبة الضريبة (%)'],
            
            // App Settings
            ['key' => 'app_name_ar', 'value' => 'مشوار', 'type' => 'string', 'group' => 'app', 'description' => 'اسم التطبيق (عربي)'],
            ['key' => 'app_name_en', 'value' => 'Mashoar', 'type' => 'string', 'group' => 'app', 'description' => 'اسم التطبيق (إنجليزي)'],
            ['key' => 'support_phone', 'value' => '+967777777777', 'type' => 'string', 'group' => 'app', 'description' => 'رقم الدعم الفني'],
            ['key' => 'support_email', 'value' => 'support@mashoar.app', 'type' => 'string', 'group' => 'app', 'description' => 'بريد الدعم الفني'],
            ['key' => 'support_whatsapp', 'value' => '+967777777777', 'type' => 'string', 'group' => 'app', 'description' => 'واتساب الدعم'],
            ['key' => 'terms_url', 'value' => 'https://mashoar.app/terms', 'type' => 'string', 'group' => 'app', 'description' => 'رابط الشروط والأحكام'],
            ['key' => 'privacy_url', 'value' => 'https://mashoar.app/privacy', 'type' => 'string', 'group' => 'app', 'description' => 'رابط سياسة الخصوصية'],
            ['key' => 'min_app_version', 'value' => '1.0.0', 'type' => 'string', 'group' => 'app', 'description' => 'الحد الأدنى لإصدار التطبيق'],
            ['key' => 'maintenance_mode', 'value' => '0', 'type' => 'boolean', 'group' => 'app', 'description' => 'وضع الصيانة'],
            
            // Maps & Location
            ['key' => 'google_maps_api_key', 'value' => '', 'type' => 'string', 'group' => 'maps', 'description' => 'Google Maps API Key'],
            ['key' => 'default_map_lat', 'value' => '15.3694', 'type' => 'number', 'group' => 'maps', 'description' => 'خط العرض الافتراضي'],
            ['key' => 'default_map_lng', 'value' => '44.1910', 'type' => 'number', 'group' => 'maps', 'description' => 'خط الطول الافتراضي'],
            ['key' => 'default_zoom_level', 'value' => '13', 'type' => 'number', 'group' => 'maps', 'description' => 'مستوى التكبير الافتراضي'],
            ['key' => 'geofencing_enabled', 'value' => '0', 'type' => 'boolean', 'group' => 'maps', 'description' => 'تفعيل تحديد المناطق'],
            
            // Features
            ['key' => 'ride_scheduling_enabled', 'value' => '1', 'type' => 'boolean', 'group' => 'features', 'description' => 'تفعيل جدولة الرحلات'],
            ['key' => 'favorite_locations_enabled', 'value' => '1', 'type' => 'boolean', 'group' => 'features', 'description' => 'تفعيل الأماكن المفضلة'],
            ['key' => 'tipping_enabled', 'value' => '1', 'type' => 'boolean', 'group' => 'features', 'description' => 'تفعيل الإكراميات'],
            ['key' => 'sos_button_enabled', 'value' => '1', 'type' => 'boolean', 'group' => 'features', 'description' => 'تفعيل زر الطوارئ'],
            
            // Notifications (Firebase)
            ['key' => 'fcm_server_key', 'value' => '', 'type' => 'string', 'group' => 'notifications', 'description' => 'Firebase Server Key'],
            ['key' => 'fcm_project_id', 'value' => '', 'type' => 'string', 'group' => 'notifications', 'description' => 'Firebase Project ID'],
            ['key' => 'fcm_sender_id', 'value' => '', 'type' => 'string', 'group' => 'notifications', 'description' => 'Firebase Sender ID'],
            
            // SMS Gateway
            ['key' => 'sms_gateway_api_key', 'value' => '', 'type' => 'string', 'group' => 'notifications', 'description' => 'SMS Gateway API Key'],
            ['key' => 'sms_gateway_url', 'value' => '', 'type' => 'string', 'group' => 'notifications', 'description' => 'SMS Gateway URL'],
        ];

        foreach ($settings as $setting) {
            DB::table('system_settings')->updateOrInsert(
                ['key' => $setting['key']],
                $setting
            );
        }
    }

    public function down(): void
    {
        // Remove added settings
        $keys = [
            'base_fare', 'per_km_rate', 'per_minute_rate', 'surge_multiplier',
            'cancellation_fee_rider', 'cancellation_fee_driver', 'night_charge_percentage',
            'max_concurrent_trips', 'min_rating_to_stay_active', 'auto_assign_timeout',
            'max_waiting_time', 'free_cancellation_window', 'max_trip_distance',
            'cash_enabled', 'wallet_enabled', 'card_payment_enabled', 'currency_symbol', 'tax_rate',
            'app_name_ar', 'app_name_en', 'support_phone', 'support_email', 'support_whatsapp',
            'terms_url', 'privacy_url', 'min_app_version', 'maintenance_mode',
            'google_maps_api_key', 'default_map_lat', 'default_map_lng', 'default_zoom_level', 'geofencing_enabled',
            'ride_scheduling_enabled', 'favorite_locations_enabled', 'tipping_enabled', 'sos_button_enabled',
            'fcm_server_key', 'fcm_project_id', 'fcm_sender_id',
            'sms_gateway_api_key', 'sms_gateway_url',
        ];
        
        DB::table('system_settings')->whereIn('key', $keys)->delete();
    }
};
