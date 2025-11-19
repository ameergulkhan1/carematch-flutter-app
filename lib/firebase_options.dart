import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

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
        return macos;
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: "AIzaSyDJzMTzfNnAOvKsHyDfCkTWfYiK1u4TJUM",
    appId: "1:409779602382:web:281e04ce80aa9333e0a19f",
    messagingSenderId: "409779602382",
    projectId: "flowing-bazaar-468814-g0",
    authDomain: "flowing-bazaar-468814-g0.firebaseapp.com",
    storageBucket: "flowing-bazaar-468814-g0.firebasestorage.app",
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey:
        "AIzaSyDJzMTzfNnAOvKsHyDfCkTWfYiK1u4TJUM", // Use your Android API key
    appId:
        "1:409779602382:android:your-android-app-id", // Get from Firebase Console
    messagingSenderId: "409779602382",
    projectId: "flowing-bazaar-468814-g0",
    storageBucket: "flowing-bazaar-468814-g0.firebasestorage.app",
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: "AIzaSyDJzMTzfNnAOvKsHyDfCkTWfYiK1u4TJUM", // Use your iOS API key
    appId: "1:409779602382:ios:your-ios-app-id", // Get from Firebase Console
    messagingSenderId: "409779602382",
    projectId: "flowing-bazaar-468814-g0",
    storageBucket: "flowing-bazaar-468814-g0.firebasestorage.app",
    iosClientId: "your-ios-client-id", // Get from Firebase Console
    iosBundleId: "your.ios.bundle.id", // Your iOS bundle ID
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: "AIzaSyDJzMTzfNnAOvKsHyDfCkTWfYiK1u4TJUM", // Use your macOS API key
    appId: "1:409779602382:ios:your-macos-app-id", // Get from Firebase Console
    messagingSenderId: "409779602382",
    projectId: "flowing-bazaar-468814-g0",
    storageBucket: "flowing-bazaar-468814-g0.firebasestorage.app",
    iosClientId: "your-macos-client-id", // Get from Firebase Console
    iosBundleId: "your.macos.bundle.id", // Your macOS bundle ID
  );
}
