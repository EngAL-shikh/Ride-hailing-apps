# 🚗 مشروع مشوار (MotoYemen/Mashoar) 🚗
مرحبًا بك في مستودع مشروع **مشوار (Mashoar)** المتكامل! هذا المشروع عبارة عن منصة ذكية ومتقدمة لطلب سيارات الأجرة وخدمات التوصيل، مصممة خصيصًا لتلبية احتياجات السوق اليمني بتكامل تقني عالي الأداء ومزايا تفاعلية ذكية.

يحتوي هذا المستودع على جزئين أساسيين:
1. **لوحة التحكم والـ API الخلفية (Laravel Backend)**: لإدارة العمليات، وتوصيل السائقين والركاب، وتحديث إعدادات التطبيق ديناميكياً.
2. **تطبيق الهاتف الذكي (Flutter Mobile App)**: تطبيق موحد ومتعدد الصلاحيات (للركاب والسائقين) مبني باستخدام إطار عمل GetX الحديث.

---

## 📐 بنية المشروع والتقنيات المستخدمة

### 1. النظام الخلفي (mashoar_backend)
* **إطار العمل**: Laravel v11 مع حزمة Laravel Sanctum لإدارة المصادقة الآمنة عبر الـ API.
* **قاعدة البيانات**: MySQL / MariaDB تدعم الاستعلامات الجغرافية المكانية `Spatial Queries` لتحديد السائقين الأقرب باستخدام صيغ ST_Distance_Sphere.
* **إدارة التصميم الديناميكي**: يدعم المنصة نظام واجهة المستخدم الموجهة من الخادم (Server-Driven UI - SDUI) مع نظام تخزين مؤقت (Cache) متقدم لتسريع استجابة التطبيق.
* **الربط مع الخدمات**: متكامل مع Firebase Cloud Messaging (FCM) للإشعارات الفورية، و Firebase Realtime Database لتتبع السائقين مباشرة.

### 2. تطبيق الهاتف (mashoar_app)
* **إطار العمل**: Flutter مع بنية GetX لتسهيل إدارة الحالة والمسارات وهندسة التطبيق بشكل نظيف.
* **الخرائط**: Google Maps Flutter لتحديد المواقع ورسم المسارات وحساب المسافات.
* **قواعد البيانات اللحظية**: متكامل مع Firebase Realtime Database لتحديث مواقع السائقين في الخلفية وبثها فورياً للركاب.

---

## 🛠️ دليل تثبيت وتشغيل لوحة التحكم والـ API (Laravel)

يوجد الكود الخاص بالنظام الخلفي في مجلد `mashoar_backend`. اتبع الخطوات التالية لتشغيله محلياً:

### المتطلبات الأساسية
* PHP >= 8.2 (مع تفعيل إضافات pdo, openssl, mbstring, curl, spatial)
* Composer
* قاعدة بيانات MySQL أو MariaDB

### خطوات التثبيت المحفز
1. ادخل إلى مجلد النظام الخلفي:
   ```bash
   cd mashoar_backend
   ```
2. قم بتثبيت الحزم البرمجية عبر Composer:
   ```bash
   composer install
   ```
3. قم بإنشاء ملف الإعدادات البيئية `.env` من الملف النموذجي:
   ```bash
   cp .env.example .env
   ```
4. افتح ملف `.env` وقم بتهيئة الإعدادات الخاصة بقاعدة البيانات والـ Firebase:
   ```env
   DB_CONNECTION=mysql
   DB_HOST=127.0.0.1
   DB_PORT=3306
   DB_DATABASE=mashoar_db
   DB_USERNAME=root
   DB_PASSWORD=your_password

   # إعدادات Firebase الخاصة بالـ Admin SDK
   FIREBASE_PROJECT_ID=your-firebase-project-id
   FIREBASE_DATABASE_URL=https://your-firebase-project-default-rtdb.firebaseio.com
   FIREBASE_DB_SECRET=your-database-secret
   FIREBASE_CREDENTIALS=storage/app/firebase-credentials.json
   ```
5. قم بتوليد مفتاح التشفير الخاص بالتطبيق:
   ```bash
   php artisan key:generate
   ```
6. قم بإنشاء جداول قاعدة البيانات وتشغيل برامج البذر (Migrations & Seeders):
   ```bash
   php artisan migrate --seed
   ```
7. قم بتشغيل الخادم المحلي:
   ```bash
   php artisan serve --port=8000
   ```

---

## 📱 دليل تثبيت وتشغيل تطبيق الهاتف (Flutter)

يوجد كود تطبيق الهاتف في مجلد `mashoar_app`. اتبع الخطوات التالية لتشغيله:

### المتطلبات الأساسية
* Flutter SDK (أحدث إصدار مستقر)
* Android Studio أو VS Code مجهز للتطوير
* محاكي Android أو جهاز حقيقي مفعّل عليه وضع المطورين (Developer Options)

### خطوات التثبيت والتشغيل
1. ادخل إلى مجلد التطبيق:
   ```bash
   cd mashoar_app
   ```
2. قم بتحميل الحزم المطلوبة:
   ```bash
   flutter pub get
   ```
3. افتح ملف تهيئة خادم الـ API الموجود في المسار:
   `lib/app/core/config/app_config.dart`
   وقم بتغيير رابط الخادم ومفتاح الخرائط الافتراضي:
   ```dart
   class AppConfig {
     // رابط الـ API الخاص بالخادم الخلفي (استخدم IP جهازك محلياً أو رابط الاستضافة الفعلي)
     static const String apiBaseUrl =
        String.fromEnvironment('API_BASE_URL', defaultValue: 'http://YOUR_LOCAL_IP:8000');

     // مفتاح Google Maps API الاحتياطي
     static const String googleMapsApiKey = 'YOUR_GOOGLE_MAPS_API_KEY_HERE';
   }
   ```
4. قم بتشغيل التطبيق على جهازك أو المحاكي:
   ```bash
   flutter run
   ```

---

## 🔥 دليل ربط المشروع بـ Firebase

يتطلب التطبيق الربط مع Firebase لإدارة الإشعارات الفورية (FCM) والتتبع اللحظي لمواقع السيارات على الخريطة (Realtime Database). اتبع هذا الدليل خطوة بخطوة للربط بأمان:

### 1. إعداد المشروع في Firebase Console
1. توجه إلى [Firebase Console](https://console.firebase.google.com/).
2. أنشئ مشروعاً جديداً باسم مشروعك (مثال: `mashoarapp`).
3. أضف تطبيق Android إلى المشروع:
   - قم بإدخال معرف الحزمة (Package Name) المطابق تماماً للتطبيق: `com.mashoar_app`.
   - قم بإدخال SHA-1 و SHA-256 لبصمات شهادات تصحيح الأخطاء (Debug Key Store) لتمكين تسجيل الدخول ومصادقة الجهاز بنجاح.
4. قم بتحميل ملف `google-services.json` وضعه في المسار التالي داخل مجلد التطبيق (هذا الملف مخفي افتراضياً في مستودع الكود لحماية الخصوصية):
   `mashoar_app/android/app/google-services.json`

### 2. إعداد قاعدة البيانات اللحظية (Realtime Database)
1. في لوحة تحكم Firebase، اذهب إلى **Realtime Database** واضغط على **Create Database**.
2. اختر الموقع الأقرب (مثال: `Singapore` أو `Belgium`) واجعلها في وضع الاختبار مؤقتاً.
3. انسخ رابط قاعدة البيانات اللحظية وضعه في:
   - ملف `.env` الخاص بالنظام الخلفي كـ `FIREBASE_DATABASE_URL`.
   - كود Flutter في ملف `lib/firebase_options.dart` داخل خيار `databaseURL`.
4. اذهب إلى تبويب **Rules** في قاعدة البيانات، وانسخ محتويات الملف `FIREBASE_RTDB_RULES.json` والصقها هناك لتفعيل صلاحيات القراءة والكتابة الآمنة، ثم اضغط **Publish**.

### 3. إعداد حساب الخدمة للإشعارات الخلفية (Firebase Admin SDK)
1. في Firebase Console، اضغط على أيقونة الإعدادات (الترس) بجانب "Project Overview" ثم اختر **Project settings**.
2. اذهب إلى تبويب **Service accounts**.
3. اختر **Node.js** أو **PHP** ثم اضغط على زر **Generate new private key**.
4. سيتم تحميل ملف JSON يحتوي على بيانات سرية مشفرة.
5. ضع هذا الملف في مجلد آمن داخل النظام الخلفي (Laravel) على سبيل المثال:
   `mashoar_backend/storage/app/firebase-credentials.json`
   *(تأكد من عدم رفع هذا الملف أبداً للمستودعات العامة! وهو مُتجاهَل تلقائياً في ملف الـ `.gitignore`)*.
6. تأكد من تهيئة مسار الملف بشكل صحيح في ملف `.env` للباك إند عبر المتغير: `FIREBASE_CREDENTIALS`.

### 4. إعداد خيارات Firebase في Flutter (firebase_options.dart)
افتح ملف `lib/firebase_options.dart` في مجلد تطبيق Flutter، واملأ الفراغات بالقيم الخاصة بمشروعك التي حصلت عليها من لوحة تحكم Firebase:
```dart
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'YOUR_FIREBASE_API_KEY_HERE',
    appId: 'YOUR_FIREBASE_APP_ID_HERE',
    messagingSenderId: 'YOUR_FIREBASE_MESSAGING_SENDER_ID_HERE',
    projectId: 'YOUR_FIREBASE_PROJECT_ID_HERE',
    storageBucket: 'YOUR_FIREBASE_STORAGE_BUCKET_HERE',
    databaseURL: 'YOUR_FIREBASE_DATABASE_URL_HERE',
  );
```

---

## 🗺️ دليل ربط تطبيق الخرائط (Google Maps API)

يعتمد التطبيق على خرائط جوجل لعرض مواقع السيارات ورسم المسارات وحسابات المسافة والوقت.

### 1. تفعيل حزم SDK المطلوبة
1. توجه إلى [Google Cloud Console](https://console.cloud.google.com/).
2. اختر مشروعك المرتبط بـ Firebase.
3. اذهب إلى **API Library** وابحث عن **Maps SDK for Android** وقم بتفعيله بالضغط على **Enable**.
4. (إذا كنت تدعم الـ iOS) ابحث عن **Maps SDK for iOS** وقم بتفعيله أيضاً.
5. ابحث عن **Directions API** (لرسم مسارات الرحلة بين نقطة البداية والنهاية) وقم بتفعيله.

### 2. إنشاء مفتاح الخرائط وحمايته (API Key Restrictions)
1. اذهب إلى **APIs & Services** > **Credentials**.
2. اضغط على **Create Credentials** ثم اختر **API Key**.
3. قم بنسخ المفتاح الناتج وضعه في المواقع التالية في كود المشروع:
   - **في واجهة خادم الأندرويد**: افتح `mashoar_app/android/app/src/main/AndroidManifest.xml` وقم بتعديل القيمة في وسم الـ meta-data:
     ```xml
     <meta-data
         android:name="com.google.android.geo.API_KEY"
         android:value="YOUR_GOOGLE_MAPS_API_KEY_HERE"/>
     ```
   - **في كود التطبيق الموحد**: افتح `mashoar_app/lib/app/core/config/app_config.dart` وضع المفتاح في حقل `googleMapsApiKey`.
4. **توصية هامة للأمان (قبل النشر العام)**:
   - افتح إعدادات مفتاح الخرائط في Google Cloud.
   - في قسم **Application restrictions** اختر **Android apps** وأضف اسم الحزمة `com.mashoar_app` مع بصمة SHA-1 لجهازك أو خادم البناء لضمان عدم سرقة المفتاح واستخدامه خارج تطبيقك.
   - في قسم **API restrictions** اختر **Restrict key** وحدد فقط **Maps SDK for Android** و **Directions API**.

---

## 🔒 حماية البيانات الحساسة وكيفية النشر بأمان (Public Repo Setup)

لقد قمنا بتنظيف جميع كلمات المرور، روابط الاستضافات الخاصة، مفاتيح الخرائط الحقيقية، والملفات السرية الخاصة بـ Firebase من الكود المصدري ووضعنا بدلاً منها متغيرات بيئية وتكوينية واضحة مع إرشادات مبسطة.

لرفع هذا المشروع في مستودع جديد (Public) على GitHub بدون تسريب أي ملفات سرية سابقة، يرجى اتباع هذه الخطوات بدقة:

### 1. التأكد من ملفات التجاهل (.gitignore)
تم إعداد ملف التجاهل الموحد `.gitignore` في جذر المشروع ليتجاهل تلقائياً كل ما يلي:
* جميع ملفات إعداد البيئة مثل `mashoar_backend/.env`
* المجلدات والملفات الخاصة بـ Firebase وسجل المفاتيح الخاص بك مثل `firbaseFiles/` بالكامل
* ملف الإعدادات المباشرة للهاتف `mashoar_app/android/app/google-services.json`
* مجلدات البناء وملفات التخزين المؤقت للأندرويد و الـ iOS و الباك إند (`vendor/`, `node_modules/`, `build/`, `.dart_tool/`).

### 2. إنشاء مستودع Git نظيف وخالٍ من التاريخ الحساس (Fresh Git History)
إذا كنت قد قمت مسبقاً بإجراء تعديلات بوجود كلمات مرور حقيقية في مستودع محلي، ننصحك بشدة بإنشاء تاريخ Git جديد تماماً لمنع متسللي الـ APIs من قراءة الملفات القديمة عبر ميزة الـ Git History:

1. افتح مبدل الأوامر في مجلد المشروع الرئيسي `c:\xampp\htdocs\mashoar`.
2. قم بحذف مجلد `.git` القديم (احرص على أخذ نسخة احتياطية من كودك الفعلي أولاً خارج المجلد):
   ```bash
   # في نظام Windows Power Shell
   Remove-Item -Recurse -Force .git
   ```
3. قم بتهيئة Git من جديد:
   ```bash
   git init -b main
   ```
4. أضف جميع الملفات المصنفة كأمنة للبث العام:
   ```bash
   git add .
   ```
   *(بفضل ملف الـ `.gitignore` المحدث، سيتم تجاهل جميع الملفات الحساسة تلقائياً ولن تدخل في المراجعة)*.
5. قم بإنشاء أول التزام نظيف تماماً:
   ```bash
   git commit -m "Initial public commit: clean credentials and templates"
   ```
6. اربط المستودع المحلي بالمستودع الجديد على GitHub وقم بالرفع:
   ```bash
   git remote add origin https://github.com/USERNAME/NEW-REPO-NAME.git
   git branch -M main
   git push -u origin main
   ```

تهانينا! أصبح مشروعك الآن جاهزاً للمشاركة العامة وبناء مجتمع المطورين حوله بكفاءة وأمان كامل. لأي استفسارات أو تفاصيل إضافية، يرجى مراجعة أدلة التطوير الفرعية المرفقة بكل مجلد.
