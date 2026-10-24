import 'package:flutter/foundation.dart';

/// Hostname for Firebase emulators from the current runtime.
///
/// Android emulators map `localhost` to the device; use the host loopback alias.
abstract final class EmulatorHosts {
  static String get firebase {
    if (kIsWeb) {
      return 'localhost';
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return '10.0.2.2';
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
      case TargetPlatform.linux:
      case TargetPlatform.windows:
      case TargetPlatform.fuchsia:
        return 'localhost';
    }
  }
}
