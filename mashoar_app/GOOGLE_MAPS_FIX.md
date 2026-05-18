# Google Maps Fix Guide

## الخطأ الحالي:
```
Error requesting API token. StatusCode=INVALID_ARGUMENT
Authorization failure.
```

## الحل:

### 1. تفعيل Maps SDK for Android:
- اذهب إلى: https://console.cloud.google.com/apis/library
- ابحث عن: "Maps SDK for Android"
- اضغط: **Enable**

### 2. التحقق من API Key Restrictions:
- اذهب إلى: https://console.cloud.google.com/apis/credentials
- افتح الـ API key الخاص بك (YOUR_API_KEY_HERE)
- في "API restrictions":
  - اختر "Restrict key"
  - أضف "Maps SDK for Android" إلى القائمة
  - أو اختر "Don't restrict key" مؤقتاً للاختبار

### 3. التحقق من Application Restrictions:
- Application restrictions: **Android apps**
- Package name: `com.mashoar_app`
- SHA-1 fingerprint: `7A:25:BA:EF:C0:E6:D0:F2:5D:AE:09:18:61:0F:7A:DB:7B:88:E5:24`

### 4. حفظ التغييرات:
- اضغط **Save**
- انتظر 5-10 دقائق

### 5. إعادة بناء التطبيق:
```bash
cd mashoar_app
flutter clean
flutter pub get
flutter run
```

## ملاحظات:
- تأكد من أن Maps SDK for Android مفعل
- تأكد من أن الـ API key غير مقيد أو مقيد بـ Maps SDK for Android فقط
- Package name و SHA-1 يجب أن يكونا مطابقين تماماً
