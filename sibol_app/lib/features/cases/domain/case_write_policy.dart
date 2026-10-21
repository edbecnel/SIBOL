import 'package:sibol_app/features/cases/domain/entities/case_record.dart';
import 'package:sibol_app/features/reporting/domain/report_status.dart';

/// Client-side write policy for fictional cases (complements Firestore rules).
class CaseWritePolicy {
  /// New cases must start with [ReportStatus.notSubmitted].
  static String? validateForCreate(CaseRecord record) {
    if (record.reportStatus != ReportStatus.notSubmitted) {
      return 'New cases must use report status notSubmitted.';
    }
    return null;
  }

  /// Updates must not change server-controlled reporting state.
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
    return null;
  }
}
