import 'package:sibol_app/features/cases/domain/case_status.dart';
import 'package:sibol_app/features/reporting/domain/report_status.dart';

/// User-facing case labels (no raw Firestore enum values).
abstract final class CasePresentationLabels {
  static String lifecycleStatus(CaseStatus status) {
    switch (status) {
      case CaseStatus.active:
        return 'Active case';
      case CaseStatus.followUpScheduled:
        return 'Follow-up scheduled';
      case CaseStatus.followUpCompleted:
        return 'Follow-up completed';
      case CaseStatus.closed:
        return 'Closed case';
    }
  }

  static String aggregateReportInclusion(ReportStatus status) {
    switch (status) {
      case ReportStatus.notSubmitted:
        return 'Aggregate report: Not yet included in a submitted report';
      case ReportStatus.pendingSubmit:
        return 'Aggregate report: Queued for submission';
      case ReportStatus.submitted:
        return 'Aggregate report: Included in a submitted report';
      case ReportStatus.submitFailed:
        return 'Aggregate report: Submission failed — review and retry';
    }
  }

  /// Sync copy from Firestore metadata (not connectivity).
  static String? synchronizationStatus({
    required bool isFromCache,
    required bool hasPendingWrites,
  }) {
    if (hasPendingWrites) {
      return 'Saved locally — awaiting synchronization';
    }
    if (isFromCache) {
      return 'Showing saved data — checking for updates';
    }
    return 'Server confirmed';
  }

  static String saveConfirmationSnackbar({
    required bool hasPendingWritesHint,
  }) {
    if (hasPendingWritesHint) {
      return 'Saved on this device. Awaiting server confirmation when online.';
    }
    return 'Saved and confirmed on the server.';
  }
}
