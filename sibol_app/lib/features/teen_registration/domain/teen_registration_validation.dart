import 'package:sibol_app/features/auth/domain/teen_profile_validation.dart';
import 'package:sibol_app/features/cases/domain/case_date_of_birth.dart';

/// Client-side validation for teen self-registration (mirrors server rules).
class TeenRegistrationValidation {
  static String? validateSignInEmail(String value) {
    final email = value.trim();
    if (email.isEmpty || !email.contains('@')) {
      return 'Enter a valid sign-in email address.';
    }
    return null;
  }

  static String? validatePasswords({
    required String password,
    required String confirm,
  }) {
    if (password.length < 8) return 'Password must be at least 8 characters.';
    if (password != confirm) return 'Passwords do not match.';
    return null;
  }

  static String? validateIdentity({
    required String fullName,
    required String dateOfBirth,
    required String contactEmail,
    required String contactPhone,
    required bool barangaySelected,
  }) {
    if (!barangaySelected) {
      return 'Select a Barangay for assistance routing.';
    }
    final profileError = TeenProfileValidation.validateProfile(
      displayName: fullName,
      dateOfBirth: dateOfBirth.trim().isEmpty ? null : dateOfBirth.trim(),
      contactEmail: contactEmail.trim().isEmpty ? null : contactEmail.trim(),
      contactPhone: contactPhone.trim().isEmpty ? null : contactPhone.trim(),
      barangay: 'selected',
    );
    return profileError;
  }

  static int? computedAge(String dateOfBirth) {
    final parsed = CaseDateOfBirth.parse(dateOfBirth);
    if (parsed == null) return null;
    return CaseDateOfBirth.currentAge(parsed);
  }

  static String? validateBeforeAccountCreation({
    required String fullName,
    required String dateOfBirth,
    required String contactEmail,
    required String contactPhone,
    required bool barangaySelected,
    required String signInEmail,
    required String password,
    required String confirmPassword,
    required bool privacyConsent,
  }) {
    final identity = validateIdentity(
      fullName: fullName,
      dateOfBirth: dateOfBirth,
      contactEmail: contactEmail,
      contactPhone: contactPhone,
      barangaySelected: barangaySelected,
    );
    if (identity != null) return identity;

    final emailError = validateSignInEmail(signInEmail);
    if (emailError != null) return emailError;

    final passwordError = validatePasswords(
      password: password,
      confirm: confirmPassword,
    );
    if (passwordError != null) return passwordError;

    if (!privacyConsent) {
      return 'Acknowledge the privacy notice to continue.';
    }
    return null;
  }

  static String? validateBeforeProfileCompletion({
    required String fullName,
    required String dateOfBirth,
    required String contactEmail,
    required String contactPhone,
    required bool barangaySelected,
    required bool privacyConsent,
  }) {
    final identity = validateIdentity(
      fullName: fullName,
      dateOfBirth: dateOfBirth,
      contactEmail: contactEmail,
      contactPhone: contactPhone,
      barangaySelected: barangaySelected,
    );
    if (identity != null) return identity;
    if (!privacyConsent) {
      return 'Acknowledge the privacy notice to continue.';
    }
    return null;
  }
}
