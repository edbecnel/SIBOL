import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

import 'package:sibol_app/config/firebase_options.dart';

/// Local Firebase Emulator Suite project id (not production `sibol-286d0`).
abstract final class EmulatorFirebaseOptions {
  static const String projectId = 'demo-sibol-emulator';

  static FirebaseOptions get currentPlatform {
    final base = DefaultFirebaseOptions.currentPlatform;
    return FirebaseOptions(
      apiKey: base.apiKey,
      appId: base.appId,
      messagingSenderId: base.messagingSenderId,
      projectId: projectId,
      storageBucket: base.storageBucket,
      iosBundleId: base.iosBundleId,
    );
  }
}
