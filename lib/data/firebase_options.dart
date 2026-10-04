// ─── Firebase Options ────────────────────────────────────────────────────────
// Same Firebase project used by the SAMS React web app (sams-flutter-d6499).
// All Firestore collections are shared between mobile and web.

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        return web;
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyC_3178BD_7beTVrB9Ovn-DMZRYpW58ddg',
    appId: '1:707817556817:web:639b68dda0a8652f28a170',
    messagingSenderId: '707817556817',
    projectId: 'sams-flutter-d6499',
    authDomain: 'sams-flutter-d6499.firebaseapp.com',
    storageBucket: 'sams-flutter-d6499.firebasestorage.app',
    measurementId: 'G-0T1YGWDS58',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyC_3178BD_7beTVrB9Ovn-DMZRYpW58ddg',
    appId: '1:707817556817:web:639b68dda0a8652f28a170',
    messagingSenderId: '707817556817',
    projectId: 'sams-flutter-d6499',
    storageBucket: 'sams-flutter-d6499.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyC_3178BD_7beTVrB9Ovn-DMZRYpW58ddg',
    appId: '1:707817556817:web:639b68dda0a8652f28a170',
    messagingSenderId: '707817556817',
    projectId: 'sams-flutter-d6499',
    storageBucket: 'sams-flutter-d6499.firebasestorage.app',
    iosBundleId: 'com.sams.mobileapp',
  );
}
