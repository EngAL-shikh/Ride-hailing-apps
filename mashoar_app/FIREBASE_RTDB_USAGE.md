# استخدام Firebase Realtime Database في مشوار

## الهدف من Realtime Database

حسب الخطة (Phase 5.2)، Firebase Realtime Database يُستخدم لتتبع موقع السائق **مباشرة** من التطبيق إلى Firebase، بدون المرور عبر Laravel server.

## البنية (Structure)

```
/trips/{trip_id}/driver_loc
  - latitude: double
  - longitude: double
  - heading: double (optional)
  - timestamp: int (milliseconds since epoch)
```

## التدفق (Flow)

### 1. السائق (Driver)
- عند بدء رحلة نشطة (`assigned` أو `in_progress`)
- يبدأ `DriverController._startFirebaseTracking()`
- يرسل موقعه كل 5-10 ثواني إلى:
  ```
  /trips/{trip_id}/driver_loc
  ```

### 2. الراكب (Rider)
- يقرأ موقع السائق من نفس المسار:
  ```
  /trips/{trip_id}/driver_loc
  ```
- يعرض الموقع على الخريطة في الوقت الفعلي
- لا يحتاج للاتصال بـ Laravel API

### 3. التتبع العام (Share Ride)
- رابط عام: `https://mashoar.app/share/{trip_id}`
- Blade template يقرأ من Firebase Realtime Database
- يعرض موقع السائق على Google Maps JS API

## المزايا

1. **سرعة**: لا يوجد round-trip عبر server
2. **Real-time**: تحديثات فورية
3. **موفر**: يقلل الحمل على Laravel server
4. **أمان**: فقط السائق يكتب، الراكب والعائلة يقرأون

## الكود الحالي

### DriverController
```dart
void _startFirebaseTracking() {
  if (activeTripId.value.isEmpty) return;
  // يبدأ إرسال الموقع كل 5-10 ثواني
}

Future<void> _sendLocationToFirebase(Position position) async {
  await _tracking.updateDriverLocation(
    tripId: activeTripId.value,
    lat: position.latitude,
    lng: position.longitude,
  );
}
```

### RealtimeTrackingService
- `updateDriverLocation()`: يكتب الموقع في Firebase
- `listenToDriverLocation()`: يستمع لتحديثات الموقع (للراكب)

## ملاحظات مهمة

1. **الأمان**: يجب إضافة Firebase Security Rules:
   ```json
   {
     "rules": {
       "trips": {
         "$tripId": {
           "driver_loc": {
             ".write": "auth != null && root.child('trips').child($tripId).child('driver_id').val() == auth.uid",
             ".read": "auth != null"
           }
         }
       }
     }
   }
   ```

2. **التنظيف**: حذف بيانات الموقع بعد انتهاء الرحلة (اختياري)

3. **الخطة**: هذا يطابق Phase 5.2 من الخطة - Direct app-to-Firebase tracking
