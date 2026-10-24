import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sibol_app/features/reporting/domain/entities/moph_aggregate_report.dart';

class MophAggregateReportModel {
  MophAggregateReportModel({
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

  factory MophAggregateReportModel.fromFirestore(
    String reportId,
    Map<String, dynamic> data,
  ) {
    return MophAggregateReportModel(
      reportId: reportId,
      barangay: data['barangay'] as String,
      orgId: data['orgId'] as String? ?? '',
      submittedAt: (data['submittedAt'] as Timestamp).toDate(),
      submittedByUid: data['submittedByUid'] as String,
      totalCaseCount: data['totalCaseCount'] as int,
      activeCaseCount: data['activeCaseCount'] as int,
      followUpScheduledCount: data['followUpScheduledCount'] as int,
      followUpCompletedCount: data['followUpCompletedCount'] as int,
      closedCaseCount: data['closedCaseCount'] as int,
      reportStatus: data['reportStatus'] as String,
      acceptedAt: (data['acceptedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestoreCreate() {
    return {
      'barangay': barangay,
      'orgId': orgId,
      'submittedAt': FieldValue.serverTimestamp(),
      'submittedByUid': submittedByUid,
      'totalCaseCount': totalCaseCount,
      'activeCaseCount': activeCaseCount,
      'followUpScheduledCount': followUpScheduledCount,
      'followUpCompletedCount': followUpCompletedCount,
      'closedCaseCount': closedCaseCount,
      'reportStatus': reportStatus,
      'acceptedAt': FieldValue.serverTimestamp(),
    };
  }

  MophAggregateReport toEntity() {
    return MophAggregateReport(
      reportId: reportId,
      barangay: barangay,
      submittedAt: submittedAt,
      submittedByUid: submittedByUid,
      totalCaseCount: totalCaseCount,
      activeCaseCount: activeCaseCount,
      followUpScheduledCount: followUpScheduledCount,
      followUpCompletedCount: followUpCompletedCount,
      closedCaseCount: closedCaseCount,
      reportStatus: reportStatus,
      acceptedAt: acceptedAt,
    );
  }
}
