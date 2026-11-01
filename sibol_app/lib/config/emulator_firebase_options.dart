import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Local Firebase Emulator Suite project id (not production `sibol-286d0`).
///
/// Uses synthetic [FirebaseOptions] so native SDKs do not derive production
/// `sibol-286d0` from the registered Android/iOS app id when talking to emulators.
abstract final class EmulatorFirebaseOptions {
  static const String projectId = 'demo-sibol-emulator';

  static const FirebaseOptions _demo = FirebaseOptions(
    // Public Android client key (same as [DefaultFirebaseOptions.android]); required
    // by native Firebase SDK format checks when calling emulated Functions.
    apiKey: 'AIzaSyAsHqvJPo-z9UKax3lhEnm9lEMVrPkFg2w',
    appId: '1:demo-sibol-emulator:android:emulator-demo',
    messagingSenderId: 'demo-sibol-emulator',
    projectId: projectId,
    storageBucket: '$projectId.appspot.com',
  );

  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError('Flutter Web is not authorized for SIBOL.');
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
      case TargetPlatform.iOS:
        return _demo;
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
      case TargetPlatform.fuchsia:
        throw UnsupportedError('SIBOL supports Android and iOS only.');
    }
  }
}
