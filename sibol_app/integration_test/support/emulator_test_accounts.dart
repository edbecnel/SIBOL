/// Canonical synthetic emulator identities (emails only — passwords via dart-defines).
abstract final class EmulatorTestAccounts {
  static const teenEmail = 'teen.demo@sibol.local';
  static const barangayEmail = 'barangay.demo@sibol.local';
  static const mophEmail = 'moph.demo@sibol.local';

  static String emailForRole(String roleFirestoreValue) {
    switch (roleFirestoreValue) {
      case 'teen':
        return teenEmail;
      case 'barangay':
        return barangayEmail;
      case 'moph':
        return mophEmail;
      default:
        throw ArgumentError('Unknown demo role: $roleFirestoreValue');
    }
  }
}

/// Passwords from `--dart-define` (never log or embed in source).
class EmulatorTestCredentials {
  const EmulatorTestCredentials({
    required this.teenPassword,
    required this.barangayPassword,
    required this.mophPassword,
  });

  factory EmulatorTestCredentials.fromEnvironment() {
    const teen = String.fromEnvironment('SIBOL_DEVICE_TEST_TEEN_PASSWORD');
    const barangay = String.fromEnvironment('SIBOL_DEVICE_TEST_BARANGAY_PASSWORD');
    const moph = String.fromEnvironment('SIBOL_DEVICE_TEST_MOPH_PASSWORD');
    if (teen.isEmpty || barangay.isEmpty || moph.isEmpty) {
      throw StateError(
        'SIBOL_DEVICE_TEST_TEEN_PASSWORD, SIBOL_DEVICE_TEST_BARANGAY_PASSWORD, '
        'and SIBOL_DEVICE_TEST_MOPH_PASSWORD dart-defines are required.',
      );
    }
    return EmulatorTestCredentials(
      teenPassword: teen,
      barangayPassword: barangay,
      mophPassword: moph,
    );
  }

  final String teenPassword;
  final String barangayPassword;
  final String mophPassword;

  String passwordForEmail(String email) {
    switch (email) {
      case EmulatorTestAccounts.teenEmail:
        return teenPassword;
      case EmulatorTestAccounts.barangayEmail:
        return barangayPassword;
      case EmulatorTestAccounts.mophEmail:
        return mophPassword;
      default:
        throw ArgumentError('No configured password for $email');
    }
  }
}
