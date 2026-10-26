import 'package:sibol_app/features/cases/domain/case_completeness.dart';
import 'package:sibol_app/features/cases/domain/case_subject_kind.dart';
import 'package:sibol_app/features/cases/domain/entities/case_record.dart';
import 'package:sibol_app/features/reporting/domain/report_status.dart';

/// Client-side write policy for cases (complements Firestore rules).
class CaseWritePolicy {
  static String? validateForCreate(CaseRecord record) {
    if (record.reportStatus != ReportStatus.notSubmitted) {
      return 'New cases must use report status notSubmitted.';
    }
    final tier = record.caseCompleteness ?? record.completeness;
    if (tier == CaseCompleteness.draft) return null;
    return validateSubjectImmutabilityPreconditions(record);
  }

  static String? validateForUpdate({
    required CaseRecord updated,
    required CaseRecord existing,
  }) {
    if (updated.caseId != existing.caseId) {
      return 'Case identifier cannot change.';
    }
    if (updated.createdAt != existing.createdAt) {
      return 'Created date cannot change.';
    }
    if (updated.reportStatus != existing.reportStatus) {
      return 'Report status cannot be changed from the app.';
    }
    if (existing.teenUid != null &&
        existing.teenUid!.isNotEmpty &&
        updated.teenUid != existing.teenUid) {
      return 'This case is already linked to a teen account and cannot be reassigned.';
    }
    if (existing.resolvedSubjectKind != updated.resolvedSubjectKind &&
        existing.subjectKind != null) {
      return 'Registration classification cannot change after creation.';
    }
    return validateSubjectImmutabilityPreconditions(updated);
  }

  static String? validateSubjectImmutabilityPreconditions(CaseRecord record) {
    if (record.resolvedSubjectKind == CaseSubjectKind.registered &&
        (record.teenUid == null || record.teenUid!.trim().isEmpty)) {
      return 'Registered cases require a verified teen account link.';
    }
    return null;
  }
}
