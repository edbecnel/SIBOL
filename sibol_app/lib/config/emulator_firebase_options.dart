import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

import 'firebase_options.dart';

/// Local Firebase Emulator Suite project id (not production `sibol-286d0`).
///
/// Android uses synthetic demo client ids (supported by the Android SDK).
/// iOS uses FlutterFire-registered [DefaultFirebaseOptions.ios] app credentials
/// with [projectId] forced to [projectId] so native + Dart agree with
/// [GoogleService-Info-Debug.plist] (see FIREBASE_SETUP.md / MVR isolation).
abstract final class EmulatorFirebaseOptions {
  static const String projectId = 'demo-sibol-emulator';

  static const FirebaseOptions _demoAndroid = FirebaseOptions(
    apiKey: 'AIzaSyAsHqvJPo-z9UKax3lhEnm9lEMVrPkFg2w',
    appId: '1:demo-sibol-emulator:android:emulator-demo',
    messagingSenderId: 'demo-sibol-emulator',
    projectId: projectId,
    storageBucket: '$projectId.appspot.com',
  );

  /// Matches bundled [GoogleService-Info-Debug.plist] (registered iOS app id + emulator project).
  static FirebaseOptions get _demoIos => FirebaseOptions(
        apiKey: DefaultFirebaseOptions.ios.apiKey,
        appId: DefaultFirebaseOptions.ios.appId,
        messagingSenderId: DefaultFirebaseOptions.ios.messagingSenderId,
        projectId: projectId,
        storageBucket: '$projectId.appspot.com',
        iosBundleId: DefaultFirebaseOptions.ios.iosBundleId,
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
