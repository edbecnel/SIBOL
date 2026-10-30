import 'package:sibol_app/features/cases/domain/case_status.dart';
import 'package:sibol_app/features/cases/domain/entities/case_record.dart';

/// Status counts for cases at a single demonstration barangay site.
class BarangayReportAggregateCounts {
  const BarangayReportAggregateCounts({
    required this.barangay,
    required this.totalCaseCount,
    required this.activeCaseCount,
    required this.followUpScheduledCount,
    required this.followUpCompletedCount,
    required this.closedCaseCount,
  });

  final String barangay;
  final int totalCaseCount;
  final int activeCaseCount;
  final int followUpScheduledCount;
  final int followUpCompletedCount;
  final int closedCaseCount;
}

BarangayReportAggregateCounts computeBarangayReportAggregate({
  required List<CaseRecord> cases,
  required String orgId,
  required String barangay,
}) {
  final scoped = cases
      .where((c) => c.orgId == orgId && c.countsTowardReporting)
      .toList();
  var active = 0;
  var followUpScheduled = 0;
  var followUpCompleted = 0;
  var closed = 0;
  for (final caseRecord in scoped) {
    switch (caseRecord.caseStatus.lifecycleCanonical) {
      case CaseStatus.open:
      case CaseStatus.active:
        active++;
      case CaseStatus.inProgress:
      case CaseStatus.followUpScheduled:
        followUpScheduled++;
      case CaseStatus.followUpCompleted:
      case CaseStatus.resolved:
        followUpCompleted++;
      case CaseStatus.closed:
        closed++;
    }
  }
  return BarangayReportAggregateCounts(
    barangay: barangay,
    totalCaseCount: scoped.length,
    activeCaseCount: active,
    followUpScheduledCount: followUpScheduled,
    followUpCompletedCount: followUpCompleted,
    closedCaseCount: closed,
  );
}
