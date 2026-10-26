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

  static String? listContactHint(CaseRecord record) {
    if (record.completeness == CaseCompleteness.draft) {
      return 'Contact details required before activation';
    }
    final hasEmail =
        record.contactEmail != null && record.contactEmail!.trim().isNotEmpty;
    final hasPhone =
        record.contactPhone != null && record.contactPhone!.trim().isNotEmpty;
    if (CaseSubjectKind.resolveStored(record.subjectKind?.firestoreValue) ==
        CaseSubjectKind.registered) {
      if (record.linkedAccountEmail != null &&
          record.linkedAccountEmail!.trim().isNotEmpty) {
        return record.linkedAccountEmail!.trim();
      }
      if (hasPhone && !hasEmail) {
        return 'Phone contact on file — see details';
      }
    }
    if (hasEmail || hasPhone) {
      return 'Contact on file — see details';
    }
    return null;
  }
}
