import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macOS;
      case TargetPlatform.windows:
        return windows;
      default:
        return android;
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCk7eXlrfmfxHrEGLBg6uGKhlh3VzqPHYU',
    appId: '1:145893311915:android:c73bff86d975f32ada3eee',
    messagingSenderId: '145893311915',
    projectId: 'alacartes',
    storageBucket: 'alacartes.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCk7eXlrfmfxHrEGLBg6uGKhlh3VzqPHYU',
    appId: '1:145893311915:ios:c73bff86d975f32ada3eee',
    messagingSenderId: '145893311915',
    projectId: 'alacartes',
    storageBucket: 'alacartes.firebasestorage.app',
  );

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCk7eXlrfmfxHrEGLBg6uGKhlh3VzqPHYU',
    appId: '1:145893311915:web:c73bff86d975f32ada3eee',
    messagingSenderId: '145893311915',
    projectId: 'alacartes',
    storageBucket: 'alacartes.firebasestorage.app',
  );

  static const FirebaseOptions macOS = FirebaseOptions(
    apiKey: 'AIzaSyCk7eXlrfmfxHrEGLBg6uGKhlh3VzqPHYU',
    appId: '1:145893311915:macos:c73bff86d975f32ada3eee',
    messagingSenderId: '145893311915',
    projectId: 'alacartes',
    storageBucket: 'alacartes.firebasestorage.app',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyCk7eXlrfmfxHrEGLBg6uGKhlh3VzqPHYU',
    appId: '1:145893311915:windows:c73bff86d975f32ada3eee',
    messagingSenderId: '145893311915',
    projectId: 'alacartes',
    storageBucket: 'alacartes.firebasestorage.app',
  );
}