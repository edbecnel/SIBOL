import 'package:sibol_app/features/cases/domain/case_completeness.dart';
import 'package:sibol_app/features/cases/domain/case_subject_kind.dart';
import 'package:sibol_app/features/cases/domain/entities/case_record.dart';

class CaseIdentityPresentation {
  static String subjectClassificationLabel(CaseRecord record) {
    switch (CaseSubjectKind.resolveStored(record.subjectKind?.firestoreValue)) {
      case CaseSubjectKind.registered:
        return 'Registered SIBOL account';
      case CaseSubjectKind.unregistered:
        return 'Manual record (no SIBOL account)';
    }
  }

  static String completenessLabel(CaseRecord record) {
    switch (record.completeness) {
      case CaseCompleteness.draft:
        return 'Draft — incomplete';
      case CaseCompleteness.legacyIncomplete:
        return 'Legacy record — complete contact and DOB when ready';
      case CaseCompleteness.active:
        return 'Active case';
    }
  }

  /// Contact line on Barangay dashboard case cards (detail screen shows all fields).
  static String listCardContactLine(CaseRecord record) {
    if (record.completeness == CaseCompleteness.draft) {
      return 'Contact details required before activation';
    }
    final email = record.contactEmail?.trim();
    if (email != null && email.isNotEmpty) {
      return 'Email: $email';
    }
    final phone = record.contactPhone?.trim();
    if (phone != null && phone.isNotEmpty) {
      return 'Phone: $phone';
    }
    return 'Contact: Not provided';
  }
}
