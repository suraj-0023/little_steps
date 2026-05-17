import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) throw UnsupportedError('Web not supported');
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        throw UnsupportedError('Firebase not configured for ${defaultTargetPlatform.name}');
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAWJ9Kf_-_l7IaO-EbC4bZER3simG38YO8',
    appId: '1:465165495409:android:b86c06fcc8031a62e3bfd0',
    messagingSenderId: '465165495409',
    projectId: 'gen-lang-client-0835321556',
    storageBucket: 'gen-lang-client-0835321556.firebasestorage.app',
  );
}
