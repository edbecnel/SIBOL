import 'package:flutter/foundation.dart';

/// Environment selector via `--dart-define=ENVIRONMENT=development|staging|production`.
abstract final class EnvConfig {
  static const String environment = String.fromEnvironment(
    'ENVIRONMENT',
    defaultValue: 'development',
  );

  static bool get isDevelopment => environment == 'development';

  /// Explicit override via `--dart-define=USE_FIREBASE_EMULATORS=true|false`.
  /// When unset, debug/profile development builds use local emulators;
  /// release builds never default to emulators (live Firebase).
  static const String _useFirebaseEmulatorsDefine = String.fromEnvironment(
    'USE_FIREBASE_EMULATORS',
    defaultValue: '',
  );

  static bool get useEmulators => resolveUseFirebaseEmulators(
        useFirebaseEmulatorsDefine: _useFirebaseEmulatorsDefine,
        environment: environment,
        releaseMode: kReleaseMode,
      );

  /// When `true`, Firestore allows barangay registry reads for missing docs
  /// (rules in repo; deploy pending). When `false` (default), the app maps
  /// registry `permission-denied` to “no referral” for live Increment A rules.
  static bool get coordinationRegistryRulesV2 => const bool.fromEnvironment(
        'SIBOL_COORD_REGISTRY_RULES_V2',
        defaultValue: false,
      );
}

/// Pure resolver for [EnvConfig.useEmulators] (unit-tested).
bool resolveUseFirebaseEmulators({
  required String useFirebaseEmulatorsDefine,
  required String environment,
  required bool releaseMode,
}) {
  switch (useFirebaseEmulatorsDefine) {
    case 'true':
      return true;
    case 'false':
      return false;
    default:
      if (releaseMode) {
        return false;
      }
      return environment == 'development';
  }
}
