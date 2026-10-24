/// Environment selector via `--dart-define=ENVIRONMENT=development|staging|production`.
abstract final class EnvConfig {
  static const String environment = String.fromEnvironment(
    'ENVIRONMENT',
    defaultValue: 'development',
  );

  static bool get isDevelopment => environment == 'development';

  static bool get useEmulators => const bool.fromEnvironment(
        'USE_FIREBASE_EMULATORS',
        defaultValue: false,
      );

  /// When `true`, Firestore allows barangay registry reads for missing docs
  /// (rules in repo; deploy pending). When `false` (default), the app maps
  /// registry `permission-denied` to “no referral” for live Increment A rules.
  static bool get coordinationRegistryRulesV2 => const bool.fromEnvironment(
        'SIBOL_COORD_REGISTRY_RULES_V2',
        defaultValue: false,
      );
}
