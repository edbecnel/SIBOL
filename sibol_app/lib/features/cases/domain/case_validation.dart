import 'package:sibol_app/features/cases/domain/case_status.dart';

class CaseValidation {
  static const int minAge = 13;
  static const int maxAge = 19;

  static String? validateDemoName(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return 'Demo name is required.';
    if (trimmed.length < 2) return 'Demo name is too short.';
    return null;
  }

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
}
