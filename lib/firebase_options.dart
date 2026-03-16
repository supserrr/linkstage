// File generated for Firebase project linkstage-rw.
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
class DefaultFirebaseOptions {
  /// OAuth client IDs for Google Sign-In (used with [GoogleSignIn.initialize]).
  /// Web OAuth client (type 3 in google-services.json); required for Google Sign-In + Firebase on Android.
  static const String googleSignInServerClientId =
      '776691693274-okbi0336ekabpngr9eulat7qg86at177.apps.googleusercontent.com';
  static const String googleSignInIosClientId =
      '776691693274-0v18vkt927r8cvsilj7vvmsmcg2filrs.apps.googleusercontent.com';
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
        return windows;
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
    apiKey: 'AIzaSyCUn4hDKIE6BYSlpItrlgi0YpJUNH11LE0',
    appId: '1:776691693274:web:ed4632f7936f009bf0d7e3',
    messagingSenderId: '776691693274',
    projectId: 'linkstage-rw',
    authDomain: 'linkstage-rw.firebaseapp.com',
    databaseURL: 'https://linkstage-rw-default-rtdb.firebaseio.com',
    storageBucket: 'linkstage-rw.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDoVKNFT8Izo_HMlNw0y6n4SZO9cMEUnfM',
    appId: '1:776691693274:android:fe80b80945e68e7df0d7e3',
    messagingSenderId: '776691693274',
    projectId: 'linkstage-rw',
    databaseURL: 'https://linkstage-rw-default-rtdb.firebaseio.com',
    storageBucket: 'linkstage-rw.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAF8Ui3cHZIyNgJqg-qa-kg1S6rUX9meNA',
    appId: '1:776691693274:ios:24c035d2b80939fef0d7e3',
    messagingSenderId: '776691693274',
    projectId: 'linkstage-rw',
    databaseURL: 'https://linkstage-rw-default-rtdb.firebaseio.com',
    storageBucket: 'linkstage-rw.firebasestorage.app',
    androidClientId: '776691693274-k2v6u90s98ikch0pmtn0epjut74skoa8.apps.googleusercontent.com',
    iosClientId: '776691693274-0v18vkt927r8cvsilj7vvmsmcg2filrs.apps.googleusercontent.com',
    iosBundleId: 'com.example.flutterApplication1',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyAF8Ui3cHZIyNgJqg-qa-kg1S6rUX9meNA',
    appId: '1:776691693274:ios:24c035d2b80939fef0d7e3',
    messagingSenderId: '776691693274',
    projectId: 'linkstage-rw',
    databaseURL: 'https://linkstage-rw-default-rtdb.firebaseio.com',
    storageBucket: 'linkstage-rw.firebasestorage.app',
    androidClientId: '776691693274-k2v6u90s98ikch0pmtn0epjut74skoa8.apps.googleusercontent.com',
    iosClientId: '776691693274-0v18vkt927r8cvsilj7vvmsmcg2filrs.apps.googleusercontent.com',
    iosBundleId: 'com.example.flutterApplication1',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyCUn4hDKIE6BYSlpItrlgi0YpJUNH11LE0',
    appId: '1:776691693274:web:bf8f7926cd79ff4df0d7e3',
    messagingSenderId: '776691693274',
    projectId: 'linkstage-rw',
    authDomain: 'linkstage-rw.firebaseapp.com',
    databaseURL: 'https://linkstage-rw-default-rtdb.firebaseio.com',
    storageBucket: 'linkstage-rw.firebasestorage.app',
  );

}