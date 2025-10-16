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
    apiKey: 'AIzaSyDK6g2AAKmCJBqwrOa_DYIobLGC2mH-BhM',
    appId: '1:145893311915:android:e89a9e0e847d4968da3eee',
    messagingSenderId: '145893311915',
    projectId: 'alacartes',
    storageBucket: 'alacartes.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDK6g2AAKmCJBqwrOa_DYIobLGC2mH-BhM',
    appId: '1:145893311915:ios:e89a9e0e847d4968da3eee',
    messagingSenderId: '145893311915',
    projectId: 'alacartes',
    storageBucket: 'alacartes.firebasestorage.app',
  );

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDK6g2AAKmCJBqwrOa_DYIobLGC2mH-BhM',
    appId: '1:145893311915:web:e89a9e0e847d4968da3eee',
    messagingSenderId: '145893311915',
    projectId: 'alacartes',
    storageBucket: 'alacartes.firebasestorage.app',
  );

  static const FirebaseOptions macOS = FirebaseOptions(
    apiKey: 'AIzaSyDK6g2AAKmCJBqwrOa_DYIobLGC2mH-BhM',
    appId: '1:145893311915:macos:e89a9e0e847d4968da3eee',
    messagingSenderId: '145893311915',
    projectId: 'alacartes',
    storageBucket: 'alacartes.firebasestorage.app',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyDK6g2AAKmCJBqwrOa_DYIobLGC2mH-BhM',
    appId: '1:145893311915:windows:e89a9e0e847d4968da3eee',
    messagingSenderId: '145893311915',
    projectId: 'alacartes',
    storageBucket: 'alacartes.firebasestorage.app',
  );
}