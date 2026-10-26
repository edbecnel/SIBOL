class CaseContactValidation {
  static final RegExp _emailPattern = RegExp(
    r'^[^\s@]+@[^\s@]+\.[^\s@]+$',
  );

  static final RegExp _phonePattern = RegExp(r'^\+?[\d\s().-]{7,20}$');

  static String? validateEmail(String? value) {
    if (value == null) return null;
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;
    if (!_emailPattern.hasMatch(trimmed)) {
      return 'Enter a valid email address.';
    }
    return null;
  }

  static String? validatePhone(String? value) {
    if (value == null) return null;
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;
    final digits = trimmed.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 7 || !_phonePattern.hasMatch(trimmed)) {
      return 'Enter a valid phone number.';
    }
    return null;
  }

  static bool hasContactMethod({
    String? contactEmail,
    String? contactPhone,
  }) {
    final emailOk = contactEmail != null &&
        contactEmail.trim().isNotEmpty &&
        validateEmail(contactEmail) == null;
    final phoneOk = contactPhone != null &&
        contactPhone.trim().isNotEmpty &&
        validatePhone(contactPhone) == null;
    return emailOk || phoneOk;
  }

  static String? requireAtLeastOneContact({
    String? contactEmail,
    String? contactPhone,
  }) {
    if (hasContactMethod(
      contactEmail: contactEmail,
      contactPhone: contactPhone,
    )) {
      return null;
    }
    return 'Add an email or phone number as a contact method.';
  }
}
