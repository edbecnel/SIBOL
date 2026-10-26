import 'package:sibol_app/features/cases/domain/case_contact_validation.dart';
import 'package:sibol_app/features/cases/domain/case_date_of_birth.dart';

class TeenProfileValidation {
  static String? validateDisplayName(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return 'Full name is required.';
    if (trimmed.length < 2) return 'Full name is too short.';
    return null;
  }

  static String? validateBarangay(String value) {
    if (value.trim().isEmpty) return 'Barangay is required.';
    return null;
  }

  static String? validateProfile({
    required String displayName,
    required String? dateOfBirth,
    required String? contactEmail,
    required String? contactPhone,
    required String barangay,
  }) {
    final errors = <String?>[
      validateDisplayName(displayName),
      CaseDateOfBirth.validateForAdolescentCase(dateOfBirth),
      validateBarangay(barangay),
      CaseContactValidation.validateEmail(contactEmail),
      CaseContactValidation.validatePhone(contactPhone),
      CaseContactValidation.requireAtLeastOneContact(
        contactEmail: contactEmail,
        contactPhone: contactPhone,
      ),
    ];
    final joined = errors.whereType<String>().where((e) => e.isNotEmpty).join(' ');
    return joined.isEmpty ? null : joined;
  }
}
