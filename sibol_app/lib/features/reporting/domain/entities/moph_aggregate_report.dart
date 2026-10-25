import 'package:equatable/equatable.dart';

/// Aggregate barangay-to-MOPH report (no per-case PII).
class MophAggregateReport extends Equatable {
  const MophAggregateReport({
    required this.reportId,
    required this.barangay,
    required this.orgId,
    required this.submittedAt,
    required this.submittedByUid,
    required this.totalCaseCount,
    required this.activeCaseCount,
    required this.followUpScheduledCount,
    required this.followUpCompletedCount,
    required this.closedCaseCount,
    required this.reportStatus,
    required this.acceptedAt,
  });

  final String reportId;
  final String barangay;
  final String orgId;
  final DateTime submittedAt;
  final String submittedByUid;
  final int totalCaseCount;
  final int activeCaseCount;
  final int followUpScheduledCount;
  final int followUpCompletedCount;
  final int closedCaseCount;
  final String reportStatus;
  final DateTime acceptedAt;

  @override
  List<Object?> get props => [
        reportId,
        barangay,
        orgId,
        submittedAt,
        submittedByUid,
        totalCaseCount,
        activeCaseCount,
        followUpScheduledCount,
        followUpCompletedCount,
        closedCaseCount,
        reportStatus,
        acceptedAt,
      ];
}
