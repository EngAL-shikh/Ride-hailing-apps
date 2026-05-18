# إعداد متغيرات البيئة (.env)

## خطوات الإعداد السريع:

### 1. افتح ملف `.env` في مجلد `mashoar_backend`

### 2. أضف السطر التالي:

```env
FIREBASE_DB_URL=https://mashoarapp-default-rtdb.asia-southeast1.firebasedatabase.app
```

### 3. (اختياري) إذا كنت تستخدم Database Secret:

```env
FIREBASE_DB_SECRET=your_database_secret_here
```

**ملاحظة**: يمكنك ترك `FIREBASE_DB_SECRET` فارغاً - النظام سيستخدم Service Account credentials تلقائياً.

### 4. بعد إضافة المتغيرات، قم بتشغيل:

```bash
php artisan config:clear
```

### 5. تحقق من الإعداد:

افتح `storage/logs/laravel.log` وتأكد من عدم وجود:
- `[FirebaseSync] FIREBASE_DB_URL not configured`

إذا ظهرت هذه الرسالة، تأكد من:
1. إضافة `FIREBASE_DB_URL` إلى `.env`
2. تشغيل `php artisan config:clear`
3. إعادة تشغيل Laravel server
