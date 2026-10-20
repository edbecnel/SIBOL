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
}
