<div align="center">

# 🚗 مشوار | Mashoar 🚗

### 🌍 Dual-Language Project Documentation / وثائق المشروع ثنائية اللغة 🌍

تطبيق ذكي متكامل لطلب سيارات الأجرة وخدمات التوصيل، مصمم خصيصاً لتلبية احتياجات السوق اليمني بتكامل تقني عالي الأداء ومزايا تفاعلية لحظية.

An integrated smart ride-hailing and courier delivery platform, specifically tailored for the Yemeni market with high-performance real-time features.

---

### 👇 اختر لغة القراءة / Choose Your Language 👇

[![العربية](https://img.shields.io/badge/اقرأ_بالعربية-العربية-0052CC?style=for-the-badge&logo=gitbook&logoColor=white)](#-النسخة-العربية)
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
[![English](https://img.shields.io/badge/Read_in_English-English-059669?style=for-the-badge&logo=gitbook&logoColor=white)](#-english-version)

---

</div>

---

# 📖 English Version

Welcome to the **Mashoar (مشوار)** master repository! This repository hosts a premium, production-ready ride-hailing and delivery platform optimized for modern mobile infrastructure. 

The project consists of two core layers:
1. **Laravel Backend (mashoar_backend)**: Handles business logic, driver discovery, billing, SDUI parsing, and realtime service coordination.
2. **Flutter Mobile App (mashoar_app)**: A unified, high-fidelity app for both riders and drivers powered by the GetX state management framework.

---

## 🚀 Key Features

* **Real-time Spatial Tracking**: High-performance driver discovery using spatial database queries (`ST_Distance_Sphere`).
* **Direct App-to-Firebase Tracking**: Bypasses the main HTTP server to broadcast active driver locations directly to passengers via Firebase Realtime Database.
* **Server-Driven UI (SDUI)**: Allows instantaneous changes to the application's layout, profile designs, and theme presets directly from the admin panel with advanced caching mechanisms.
* **Trip Bidding Logic**: Seamless bidding flow with automated driver debt, commissions, and platform fees calculation.
* **Push Notifications**: Cross-platform instant alerts powered by Firebase Cloud Messaging (FCM).

---

## 🛠️ Backend Setup (Laravel v11)

The backend code is located in the `mashoar_backend` directory.

### Prerequisites
* PHP >= 8.2 (extensions: `pdo`, `openssl`, `mbstring`, `curl`, `spatial` enabled)
* Composer
* MySQL or MariaDB

### Installation Steps
1. Navigate to the backend directory:
   ```bash
   cd mashoar_backend
   ```
2. Install PHP dependencies:
   ```bash
   composer install
   ```
3. Copy environment template file:
   ```bash
   cp .env.example .env
   ```
4. Open `.env` and fill in your MySQL database details and Firebase tokens:
   ```env
   DB_CONNECTION=mysql
   DB_HOST=127.0.0.1
   DB_PORT=3306
   DB_DATABASE=mashoar_db
   DB_USERNAME=root
   DB_PASSWORD=your_password

   # Firebase settings
   FIREBASE_PROJECT_ID=your-firebase-project-id
   FIREBASE_DATABASE_URL=https://your-firebase-project-default-rtdb.firebaseio.com
   FIREBASE_DB_SECRET=your-database-secret
   FIREBASE_CREDENTIALS=storage/app/firebase-credentials.json
   ```
5. Generate application encryption key:
   ```bash
   php artisan key:generate
   ```
6. Run migrations and seed database:
   ```bash
   php artisan migrate --seed
   ```
7. Start your local server:
   ```bash
   php artisan serve --port=8000
   ```

---

## 📱 Mobile App Setup (Flutter)

The mobile app code is located in the `mashoar_app` directory.

### Prerequisites
* Flutter SDK (Latest Stable Version)
* Android Studio / VS Code (configured for mobile development)
* Emulator or physical device with Developer options active

### Installation Steps
1. Navigate to the app directory:
   ```bash
   cd mashoar_app
   ```
2. Download packages and plugins:
   ```bash
   flutter pub get
   ```
3. Open `lib/app/core/config/app_config.dart` and configure your API endpoint and Maps API Key:
   ```dart
   class AppConfig {
     // Local IP or production URL
     static const String apiBaseUrl =
        String.fromEnvironment('API_BASE_URL', defaultValue: 'http://YOUR_LOCAL_IP:8000');

     // Fallback Google Maps API Key
     static const String googleMapsApiKey = 'YOUR_GOOGLE_MAPS_API_KEY_HERE';
   }
   ```
4. Run the application:
   ```bash
   flutter run
   ```

---

## 🔥 Firebase Setup Guide

To establish secure communication between the app, the server, and the database, you must configure Firebase correctly:

### 1. Project Initialization
1. Create a project in [Firebase Console](https://console.firebase.google.com/).
2. Add an Android app with the package name: `com.mashoar_app`.
3. Provide your Debug and Release **SHA-1** and **SHA-256** fingerprints (crucial for Google Login and Device Verification).
4. Download the `google-services.json` file and place it at:
   `mashoar_app/android/app/google-services.json`

### 2. Realtime Database (RTDB) Configuration
1. Go to **Realtime Database** -> **Create Database**.
2. Select your preferred hosting location and start in test mode.
3. Add the DB URL to your backend `.env` as `FIREBASE_DATABASE_URL` and to Flutter's `firebase_options.dart` in `databaseURL`.
4. Go to **Rules** tab, copy the rules from `FIREBASE_RTDB_RULES.json` in the root folder, paste them, and click **Publish**.

### 3. Server Authentication (FCM Admin SDK)
1. Go to **Project Settings** -> **Service accounts**.
2. Under Firebase Admin SDK, select **PHP** and click **Generate new private key**.
3. Save the downloaded JSON file securely at:
   `mashoar_backend/storage/app/firebase-credentials.json`
4. Set the path in your backend `.env` file under `FIREBASE_CREDENTIALS`.

### 4. Configure Flutter Firebase Options
Open `lib/firebase_options.dart` in Flutter and specify your project options:
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

## 🗺️ Google Maps Setup Guide

1. Go to [Google Cloud Console](https://console.cloud.google.com/).
2. Select your Firebase project.
3. Enable the following API libraries:
   * **Maps SDK for Android**
   * **Maps SDK for iOS**
   * **Directions API** (used for route drawing)
4. Go to **Credentials** -> **Create Credentials** -> **API Key**.
5. Put the generated key in:
   * **AndroidManifest.xml**: Under `<meta-data android:name="com.google.android.geo.API_KEY" android:value="YOUR_GOOGLE_MAPS_API_KEY_HERE"/>`.
   * **App Config**: Under `lib/app/core/config/app_config.dart` in `googleMapsApiKey`.
6. **Key Security (Highly Recommended)**: Under key settings, restrict the key to Android apps (`com.mashoar_app` package name and SHA-1 fingerprint) and restrict the APIs to *Maps SDK for Android* and *Directions API*.

<br/>

[⬆️ Back to Language Selection / الرجوع لأعلى الصفحة](#-choose-your-language--)

---

# 📖 النسخة العربية

مرحباً بك في مستودع مشروع **مشوار (Mashoar)** المتكامل! هذا المشروع عبارة عن منصة ذكية ومتقدمة لطلب سيارات الأجرة وخدمات التوصيل، مصممة خصيصاً لتلبية احتياجات السوق اليمني بتكامل تقني عالي الأداء ومزايا تفاعلية لحظية.

يحتوي هذا المستودع على جزئين أساسيين:
1. **لوحة التحكم والـ API الخلفية (Laravel Backend)**: لإدارة العمليات، وتوصيل السائقين والركاب، وتحديث إعدادات التطبيق ديناميكياً.
2. **تطبيق الهاتف الذكي (Flutter Mobile App)**: تطبيق موحد ومتعدد الصلاحيات (للركاب والسائقين) مبني باستخدام إطار عمل GetX الحديث.

---

## 🚀 المزايا الرئيسية للمنصة

* **تتبع مكاني فوري عالي الأداء**: اكتشاف السائق الأقرب جغرافياً بالاعتماد على محرك الاستعلامات المكانية لقاعدة البيانات (`ST_Distance_Sphere`).
* **تتبع مباشر من التطبيق للـ Firebase**: بث إحداثيات السائق مباشرة للراكب عبر قاعدة البيانات اللحظية Firebase RTDB لتجنب إرهاق خادم الباك إند الرئيسي.
* **واجهات مستخدم موجهة من الخادم (SDUI)**: إمكانية تعديل تصميم الواجهات والسمات البصرية، وهيكل الصفحة الشخصية فورياً من لوحة التحكم بفضل محرك التخزين المؤقت المتقدم.
* **نظام تسعير ومزايدة ذكي**: نظام متكامل للمزايدات بين السائق والركب مع حساب دقيق لعمولات المنصة، الديون، والمحفظة الرقمية.
* **إشعارات فورية متكاملة**: إشعارات لحظية لجميع أطراف الرحلة مدعومة بـ Firebase Cloud Messaging.

---

## 🛠️ دليل تثبيت وتشغيل لوحة التحكم والـ API (Laravel)

يوجد الكود الخاص بالنظام الخلفي في مجلد `mashoar_backend`.

### المتطلبات الأساسية
* PHP >= 8.2 (مع تفعيل إضافات pdo, openssl, mbstring, curl, spatial)
* Composer
* قاعدة بيانات MySQL أو MariaDB

### خطوات التثبيت والتشغيل
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

يوجد كود تطبيق الهاتف في مجلد `mashoar_app`.

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
3. افتح ملف تهيئة خادم الـ API الموجود في المسار `lib/app/core/config/app_config.dart` وقم بتعديل رابط الخادم ومفتاح الخرائط الافتراضي:
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
4. اذهب إلى تبويب **Rules** في قاعدة البيانات، وانسخ محتويات الملف `FIREBASE_RTDB_RULES.json` في مجلد الباك إند، والصقها هناك لتفعيل صلاحيات القراءة والكتابة الآمنة، ثم اضغط **Publish**.

### 3. إعداد حساب الخدمة للإشعارات الخلفية (Firebase Admin SDK)
1. في Firebase Console، اضغط على أيقونة الإعدادات (الترس) بجانب "Project Overview" ثم اختر **Project settings**.
2. اذهب إلى تبويب **Service accounts**.
3. اختر **PHP** ثم اضغط على زر **Generate new private key**.
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

<br/>

[⬆️ الرجوع لأعلى الصفحة / Back to top](#-مشوار--mashoar-)
