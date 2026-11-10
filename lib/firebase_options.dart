// File generated for Safro Firebase setup
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'DefaultFirebaseOptions have not been configured for web.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyA-4vJ1hcE8DwgG6GARF4fgbdr-ID8YKdg',
    appId: '1:630752005921:android:52d3cd8620ae4d1e58b860',
    messagingSenderId: '630752005921',
    projectId: 'safro-af976',
    storageBucket: 'safro-af976.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyA-4vJ1hcE8DwgG6GARF4fgbdr-ID8YKdg',
    appId: '1:630752005921:android:52d3cd8620ae4d1e58b860',
    messagingSenderId: '630752005921',
    projectId: 'safro-af976',
    storageBucket: 'safro-af976.firebasestorage.app',
  );
}

