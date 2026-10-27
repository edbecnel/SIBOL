/// Client-side organization name checks (server remains authoritative).
class OrganizationNameValidation {
  static const int minLength = 2;
  static const int maxLength = 200;

  static String normalize(String raw) {
    return raw.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  /// Returns a user-facing error, or null when valid.
  static String? validateHospitalName(String raw) {
    final name = normalize(raw);
    if (name.isEmpty) {
      return 'Hospital name is required.';
    }
    if (name.length < minLength) {
      return 'Hospital name is too short.';
    }
    if (name.length > maxLength) {
      return 'Hospital name is too long.';
    }
    return null;
  }
}
