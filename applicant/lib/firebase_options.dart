import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        return linux;
      default:
        throw UnsupportedError('DefaultFirebaseOptions are not supported for this platform.');
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCF0T_dQcnj3Kd_o233SncdVgO0ePtJXis',
    appId: '1:969765136421:web:86cf78648b9dbc22cc37cc',
    messagingSenderId: '969765136421',
    projectId: 'digital-housing-society-2f27c',
    authDomain: 'digital-housing-society-2f27c.firebaseapp.com',
    storageBucket: 'digital-housing-society-2f27c.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDLF6BjT8FCTBxWVFP3nKW31g6oSu-oyLQ',
    appId: '1:969765136421:android:fbca9072bf7a1300cc37cc',
    messagingSenderId: '969765136421',
    projectId: 'digital-housing-society-2f27c',
    storageBucket: 'digital-housing-society-2f27c.firebasestorage.app',
  );
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'REPLACE_WITH_IOS_API_KEY',
    appId: '1:000000000000:ios:0000000000000000000000',
    messagingSenderId: '000000000000',
    projectId: 'replace-with-project-id',
    storageBucket: 'replace-with-project-id.appspot.com',
    iosBundleId: 'com.example.digitalHousingSociety',
  );

  static const FirebaseOptions macos = ios;

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'REPLACE_WITH_WINDOWS_API_KEY',
    appId: '1:000000000000:web:0000000000000000000000',
    messagingSenderId: '000000000000',
    projectId: 'replace-with-project-id',
    authDomain: 'replace-with-project-id.firebaseapp.com',
    storageBucket: 'replace-with-project-id.appspot.com',
  );

  static const FirebaseOptions linux = windows;
}
