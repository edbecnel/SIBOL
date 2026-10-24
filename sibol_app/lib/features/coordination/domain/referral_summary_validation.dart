abstract final class ReferralSummaryValidation {
  static const int minLength = 10;
  static const int maxLength = 2000;

  static String? validate(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.length < minLength) {
      return 'Summary must be at least $minLength characters.';
    }
    if (trimmed.length > maxLength) {
      return 'Summary must be at most $maxLength characters.';
    }
    return null;
  }
}
