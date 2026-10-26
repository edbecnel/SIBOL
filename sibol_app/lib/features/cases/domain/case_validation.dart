import 'package:sibol_app/features/cases/domain/case_completeness.dart';
import 'package:sibol_app/features/cases/domain/case_contact_validation.dart';
import 'package:sibol_app/features/cases/domain/case_date_of_birth.dart';
import 'package:sibol_app/features/cases/domain/case_status.dart';
import 'package:sibol_app/features/cases/domain/case_subject_kind.dart';
import 'package:sibol_app/features/cases/domain/entities/case_record.dart';

class CaseValidation {
  static const int minAge = CaseAdolescentAgeBounds.min;
  static const int maxAge = CaseAdolescentAgeBounds.max;

  static String? validateFullName(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return 'Full name is required.';
    if (trimmed.length < 2) return 'Full name is too short.';
    return null;
  }

  static String? validateDemoName(String value) => validateFullName(value);

  static String? validateAge(int? age) {
    if (age == null) return 'Age is required.';
    if (age < minAge || age > maxAge) {
      return 'Age must be between $minAge and $maxAge for this prototype.';
    }
    return null;
  }

  static String? validateBarangay(String value) {
    if (value.trim().isEmpty) return 'Barangay is required.';
    return null;
  }

  static String? validateCaseStatus(CaseStatus? status) {
    if (status == null) return 'Case status is required.';
    return null;
  }

  static String? validateDraft(CaseRecord record) {
    return validateFullName(record.displayFullName);
  }

  static String? validateActiveCase(CaseRecord record) {
    final errors = <String?>[
      validateFullName(record.displayFullName),
      CaseDateOfBirth.validateForAdolescentCase(record.dateOfBirth),
      validateBarangay(record.barangay),
      validateCaseStatus(record.caseStatus),
      CaseContactValidation.requireAtLeastOneContact(
        contactEmail: record.contactEmail,
        contactPhone: record.contactPhone,
      ),
      CaseContactValidation.validateEmail(record.contactEmail),
      CaseContactValidation.validatePhone(record.contactPhone),
    ];
    if (record.resolvedSubjectKind == CaseSubjectKind.registered) {
      if (record.teenUid == null || record.teenUid!.trim().isEmpty) {
        errors.add('Select a registered teen account for this case.');
      }
      if (record.linkedAccountEmail == null ||
          record.linkedAccountEmail!.trim().isEmpty) {
        errors.add(
          'Registered case linkage must be verified while online.',
        );
      }
    } else {
      if (record.teenUid != null && record.teenUid!.trim().isNotEmpty) {
        errors.add('Manual cases cannot include a SIBOL account UID.');
      }
    }
    final dob = CaseDateOfBirth.parse(record.dateOfBirth);
    if (dob != null) {
      final computed = CaseDateOfBirth.currentAge(dob);
      if (computed < minAge || computed > maxAge) {
        errors.add('Date of birth implies an age outside $minAge–$maxAge.');
      }
    }
    return errors.whereType<String>().where((e) => e.isNotEmpty).join(' ').isEmpty
        ? null
        : errors.whereType<String>().where((e) => e.isNotEmpty).join(' ');
  }

  static String? validateForWrite(CaseRecord record) {
    final tier = record.caseCompleteness ?? record.completeness;
    if (tier == CaseCompleteness.draft) {
      return validateDraft(record);
    }
    if (tier == CaseCompleteness.legacyIncomplete) {
      return validateLegacyIncomplete(record);
    }
    return validateActiveCase(record);
  }

  static String? validateLegacyIncomplete(CaseRecord record) {
    final nameError = validateFullName(record.displayFullName);
    if (nameError != null) return nameError;
    return validateAge(record.age);
  }
}
