import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Local Firebase Emulator Suite project id (not production `sibol-286d0`).
///
/// Uses synthetic [FirebaseOptions] so native SDKs do not derive production
/// `sibol-286d0` from the registered Android/iOS app id when talking to emulators.
abstract final class EmulatorFirebaseOptions {
  static const String projectId = 'demo-sibol-emulator';

  static const FirebaseOptions _demoAndroid = FirebaseOptions(
    apiKey: 'AIzaSyAsHqvJPo-z9UKax3lhEnm9lEMVrPkFg2w',
    appId: '1:demo-sibol-emulator:android:emulator-demo',
    messagingSenderId: 'demo-sibol-emulator',
    projectId: projectId,
    storageBucket: '$projectId.appspot.com',
  );

  /// Matches [GoogleService-Info-Debug.plist] (synthetic ids, not production app registration).
  static const FirebaseOptions _demoIos = FirebaseOptions(
    apiKey: 'AIzaSyAsHqvJPo-z9UKax3lhEnm9lEMVrPkFg2w',
    appId: '1:demo-sibol-emulator:ios:emulator-demo',
    messagingSenderId: 'demo-sibol-emulator',
    projectId: projectId,
    storageBucket: '$projectId.appspot.com',
    iosBundleId: 'com.most.sibol.sibolApp',
  );

  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError('Flutter Web is not authorized for SIBOL.');
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return _demoAndroid;
      case TargetPlatform.iOS:
        return _demoIos;
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
      case TargetPlatform.fuchsia:
        throw UnsupportedError('SIBOL supports Android and iOS only.');
    }
  }
}
