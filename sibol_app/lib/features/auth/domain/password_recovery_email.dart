/// Client-side checks for Firebase email password recovery (signed-out flow).
abstract final class PasswordRecoveryEmail {
  static final RegExp _basicEmail = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  /// Demonstration identifiers cannot receive Firebase reset emails.
  static bool isNonDeliverableDemoAddress(String email) {
    final normalized = email.trim().toLowerCase();
    if (normalized.isEmpty) return false;
    final domain = normalized.split('@').last;
    return domain == 'sibol.local' || domain.endsWith('.local');
  }

  static String? validateForPasswordReset(String raw) {
    final email = raw.trim();
    if (email.isEmpty) {
      return 'Enter the email address for your account.';
    }
    if (!_basicEmail.hasMatch(email)) {
      return 'Enter a valid email address.';
    }
    if (isNonDeliverableDemoAddress(email)) {
      return 'Password reset emails cannot be sent to demonstration .local addresses. '
          'Use a real email you can access, or ask a Barangay administrator for '
          'assisted account recovery.';
    }
    return null;
  }
}
