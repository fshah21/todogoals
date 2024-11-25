// File generated by FlutterFire CLI.
// ignore_for_file: type=lint
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
      return web;
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

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCBv2ydH1AJZfZpiQiC0GIGoYpfuCMes1Y',
    appId: '1:913436538919:web:13ff8c06ae387816aa7602',
    messagingSenderId: '913436538919',
    projectId: 'todogoals-ea6d4',
    authDomain: 'todogoals-ea6d4.firebaseapp.com',
    storageBucket: 'todogoals-ea6d4.firebasestorage.app',
    measurementId: 'G-K1Y0NXDG6C',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAgdPfyYGgDx5HM3yYfzXW0OuM3zyIMHVM',
    appId: '1:913436538919:android:a80f8e9fae57cd81aa7602',
    messagingSenderId: '913436538919',
    projectId: 'todogoals-ea6d4',
    storageBucket: 'todogoals-ea6d4.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyA_1TFS0ig5Je2gHEMT0CE-NhdTfJ6nki8',
    appId: '1:913436538919:ios:7e6e50f289f0d9b0aa7602',
    messagingSenderId: '913436538919',
    projectId: 'todogoals-ea6d4',
    storageBucket: 'todogoals-ea6d4.firebasestorage.app',
    iosBundleId: 'com.feyashah.todolistflutter',
  );
}
