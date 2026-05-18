# إصلاح مشاكل Firebase Realtime Database

## المشاكل المكتشفة:

1. **Firebase RTDB فارغ** - لا توجد بيانات في `/trips/{trip_id}/driver_loc`
2. **FCM لا يعمل** - FIS_AUTH_ERROR (يحتاج SHA fingerprints)
3. **activeTrip لا يتم تحديثه** - الرحلة لا تظهر كرحلة نشطة

## الإصلاحات المنفذة:

### 1. إصلاح مسار Firebase RTDB
- تم تغيير المسار من `trips/{trip_id}/driver` إلى `trips/{trip_id}/driver_loc` (حسب الخطة)
- تم إضافة logging شامل لتتبع الكتابة في Firebase

### 2. إضافة Debug Logging
- في `_checkActiveTrip`: تسجيل جميع الرحلات وحالاتها
- في `_sendLocationToFirebase`: تسجيل كل محاولة كتابة
- في `showTripAcceptedBottomSheet`: تسجيل عملية البحث عن الرحلة

### 3. Firebase Security Rules
- تم إنشاء ملف `FIREBASE_RTDB_RULES.json` مع قواعد أمان
- يجب نسخ هذه القواعد إلى Firebase Console > Realtime Database > Rules

## الخطوات المطلوبة (يدوياً):

### 1. إضافة Firebase Security Rules

1. اذهب إلى [Firebase Console](https://console.firebase.google.com/)
2. اختر مشروع `mashoarapp`
3. اذهب إلى **Realtime Database** > **Rules**
4. انسخ محتوى `FIREBASE_RTDB_RULES.json`
5. الصق في Rules editor
6. اضغط **Publish**

### 2. إصلاح FCM (FIS_AUTH_ERROR)

راجع ملف `FIREBASE_FIX.md` لإضافة SHA-1/SHA-256 fingerprints

### 3. اختبار Firebase RTDB

بعد إضافة Security Rules:
1. شغّل التطبيق كسائق
2. قبل رحلة (كراكب)
3. قبل عرض السائق
4. راقب Logcat للأخطاء:
   ```
   [RealtimeTrackingService] Writing to Firebase RTDB
   [RealtimeTrackingService] Successfully wrote to Firebase RTDB
   ```
5. تحقق من Firebase Console > Realtime Database > Data
6. يجب أن ترى: `trips/{trip_id}/driver_loc` مع بيانات الموقع

## ملاحظات:

- إذا استمرت المشكلة، تحقق من:
  1. Firebase project ID صحيح في `firebase_options.dart`
  2. Realtime Database مفعّل في Firebase Console
  3. Security Rules تم نشرها
  4. التطبيق متصل بالإنترنت
