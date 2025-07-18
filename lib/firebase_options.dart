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
        'DefaultFirebaseOptions have not been configured for web - '
        'you can reconfigure this by running the FlutterFire CLI again.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
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

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'YOUR_ANDROID_API_KEY', // Replace with your actual API key
    appId: 'YOUR_ANDROID_APP_ID', // Replace with your actual App ID
    messagingSenderId:
        'YOUR_MESSAGING_SENDER_ID', // Replace with actual sender ID
    projectId: 'YOUR_PROJECT_ID', // Replace with your Firebase project ID
    storageBucket:
        'YOUR_PROJECT_ID.appspot.com', // Replace with your storage bucket
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'YOUR_IOS_API_KEY', // Replace with your actual iOS API key
    appId: 'YOUR_IOS_APP_ID', // Replace with your actual iOS App ID
    messagingSenderId:
        'YOUR_MESSAGING_SENDER_ID', // Replace with actual sender ID
    projectId: 'YOUR_PROJECT_ID', // Replace with your Firebase project ID
    storageBucket:
        'YOUR_PROJECT_ID.appspot.com', // Replace with your storage bucket
    iosBundleId: 'com.example.civicLink',
  );
}
