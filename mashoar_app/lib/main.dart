import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'app/routes/app_pages.dart';
import 'app/theme/app_theme.dart';
import 'app/translations/app_translations.dart';

import 'package:get_storage/get_storage.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firebase_options.dart';
import 'dart:async';
import 'dart:ui';
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform;
import 'app/core/config/app_config.dart';
import 'app/core/firebase/fcm_service.dart';

void main() async {
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      // Log API configuration
      debugPrint('[BOOT] API Base URL: ${AppConfig.apiBaseUrl}');

      // Catch framework errors (build/layout/paint)
      FlutterError.onError = (FlutterErrorDetails details) {
        FlutterError.dumpErrorToConsole(details);
        // Make sure we always see something even if the UI can't mount.
        debugPrint('[BOOT][FlutterError] ${details.exceptionAsString()}');
      };

      // Catch platform/async errors
      PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
        debugPrint('[BOOT][PlatformError] $error');
        debugPrint('$stack');
        return true;
      };

      debugPrint('[BOOT] start main()');

      debugPrint('[BOOT] GetStorage.init()...');
      await GetStorage.init().timeout(const Duration(seconds: 10));
      debugPrint('[BOOT] GetStorage.init() OK');

      debugPrint('[BOOT] Firebase.initializeApp()...');
      // On Android, Firebase is often auto-initialized via google-services.json (FirebaseInitProvider).
      // Calling initializeApp(options: ...) can throw duplicate-app; prefer the no-options initializer.
      try {
        if (defaultTargetPlatform == TargetPlatform.android) {
          await Firebase.initializeApp().timeout(const Duration(seconds: 15));
          debugPrint('[BOOT] Firebase.initializeApp() OK (android/no-options)');
        } else {
          if (Firebase.apps.isEmpty) {
            await Firebase.initializeApp(
              options: DefaultFirebaseOptions.currentPlatform,
            ).timeout(const Duration(seconds: 15));
            debugPrint('[BOOT] Firebase.initializeApp() OK (created)');
          } else {
            debugPrint(
              '[BOOT] Firebase already initialized: apps=${Firebase.apps.length}',
            );
          }
        }
      } catch (e) {
        final msg = e.toString();
        if (msg.contains('duplicate-app') ||
            msg.contains('A Firebase App named "[DEFAULT]" already exists')) {
          debugPrint(
            '[BOOT] Firebase already initialized (duplicate-app ignored)',
          );
        } else {
          rethrow;
        }
      }

      debugPrint('[BOOT] AppTranslations.loadTranslations()...');
      await AppTranslations.loadTranslations().timeout(
        const Duration(seconds: 10),
      );
      debugPrint('[BOOT] AppTranslations.loadTranslations() OK');

      // Initialize FCM
      debugPrint('[BOOT] Initializing FCM...');
      final fcmService = FcmService();
      await fcmService.initialize();
      debugPrint('[BOOT] FCM initialized OK');

      ErrorWidget.builder = (FlutterErrorDetails details) {
        return Material(
          color: const Color(0xFFFFFFFF),
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Startup Error:\n${details.exceptionAsString()}',
                style: const TextStyle(color: Color(0xFFD32F2F)),
              ),
            ),
          ),
        );
      };

      debugPrint('[BOOT] runApp()');
      runApp(const MyApp());
      debugPrint('[BOOT] runApp() done');
    },
    (Object error, StackTrace stack) {
      debugPrint('[BOOT][ZonedGuarded] $error');
      debugPrint('$stack');
    },
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Mashoar',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light,
      // RTL Support for Arabic
      locale: const Locale('ar', 'SA'),
      fallbackLocale: const Locale('ar', 'SA'),
      translations: AppTranslations(),
      // Routes
      initialRoute: AppPages.initial,
      getPages: AppPages.routes,
      // Localization delegates
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('ar', 'SA'), Locale('en', 'US')],
    );
  }
}
