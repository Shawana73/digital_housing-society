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
    apiKey: 'AIzaSyC0h9ON_3_QHZbRi66RtWMH8O7fzxghIvY',
    appId: '1:545528218735:web:0e053cc2e80c0412d8399a',
    messagingSenderId: '545528218735',
    projectId: 'digital-housing-society-system',
    authDomain: 'digital-housing-society-system.firebaseapp.com',
    storageBucket: 'digital-housing-society-system.firebasestorage.app',
    measurementId: 'G-9KMZCDTZPT',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCnpdHyImScahbWUR8LH0_MvcyEw5eGfKg',
    appId: '1:545528218735:android:3ff903411d167b35d8399a',
    messagingSenderId: '545528218735',
    projectId: 'digital-housing-society-system',
    storageBucket: 'digital-housing-society-system.firebasestorage.app',
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
