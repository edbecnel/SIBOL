import 'package:flutter/foundation.dart';

/// Hostname for Firebase emulators from the current runtime.
///
/// Android emulators map `localhost` to the device; use the host loopback alias.
abstract final class EmulatorHosts {
  /// When `true` with [adb reverse] for 9099/8195/5001, Android integration tests
  /// can reach host emulators via `127.0.0.1` instead of `10.0.2.2`.
  static const bool androidUseLocalhostViaReverse = bool.fromEnvironment(
    'SIBOL_ANDROID_USE_LOCALHOST_EMULATOR',
    defaultValue: false,
  );

  static String get firebase {
    if (kIsWeb) {
      return 'localhost';
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return androidUseLocalhostViaReverse ? '127.0.0.1' : '10.0.2.2';
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
      case TargetPlatform.linux:
      case TargetPlatform.windows:
      case TargetPlatform.fuchsia:
        return 'localhost';
    }
  }
}
