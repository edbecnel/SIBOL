/// Provisional REG-C policy (Product Owner decisions pending).
abstract final class TeenOnboardingPolicy {
  /// When true, [regRegisterTeenAccount] requires verified email (server).
  static const requireEmailVerificationBeforeProfile = false;

  /// When true, assistance UI is gated until email is verified.
  static const requireEmailVerificationBeforeAssistance = false;

  static const privacyNoticeVersion = '2026-provisional-reg-c';

  static const privacyNoticeText =
      'This notice is provisional and does not constitute legal consent. '
      'Selecting a Barangay routes assistance requests only; it does not verify '
      'your residence, identity, or eligibility. SIBOL stores minimal account '
      'information for demonstration purposes.';
}

enum TeenOnboardingStatus {
  complete,
  pendingEmailVerification,
  profileIncomplete,
}

TeenOnboardingStatus? parseTeenOnboardingStatus(String? raw) {
  switch (raw) {
    case 'complete':
      return TeenOnboardingStatus.complete;
    case 'pending_email_verification':
      return TeenOnboardingStatus.pendingEmailVerification;
    case 'profile_incomplete':
      return TeenOnboardingStatus.profileIncomplete;
    default:
      return null;
  }
}
