import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

// Generated manually from firbaseFiles/google-services.json (Android only).
// Do NOT include service account keys in the mobile app.

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError('Web Firebase options are not configured.');
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
      case TargetPlatform.fuchsia:
        throw UnsupportedError('FirebaseOptions for this platform are not configured.');
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'YOUR_FIREBASE_API_KEY_HERE',
    appId: 'YOUR_FIREBASE_APP_ID_HERE',
    messagingSenderId: 'YOUR_FIREBASE_MESSAGING_SENDER_ID_HERE',
    projectId: 'YOUR_FIREBASE_PROJECT_ID_HERE',
    storageBucket: 'YOUR_FIREBASE_STORAGE_BUCKET_HERE',
    // Common default pattern. If your RTDB URL differs, update it in firbaseFiles and here.
    databaseURL: 'YOUR_FIREBASE_DATABASE_URL_HERE',
  );
}

