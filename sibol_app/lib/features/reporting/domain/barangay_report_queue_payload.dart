import 'package:sibol_app/features/reporting/domain/barangay_report_aggregate.dart';

class BarangayReportQueuePayload {
  static Map<String, String> encode({
    required String reportId,
    required String orgId,
    required String submittedByUid,
    required BarangayReportAggregateCounts counts,
  }) {
    return {
      'reportId': reportId,
      'orgId': orgId,
      'submittedByUid': submittedByUid,
      'barangay': counts.barangay,
      'totalCaseCount': '${counts.totalCaseCount}',
      'activeCaseCount': '${counts.activeCaseCount}',
      'followUpScheduledCount': '${counts.followUpScheduledCount}',
      'followUpCompletedCount': '${counts.followUpCompletedCount}',
      'closedCaseCount': '${counts.closedCaseCount}',
    };
  }

  static BarangayReportAggregateCounts countsFrom(Map<String, String> payload) {
    return BarangayReportAggregateCounts(
      barangay: payload['barangay'] ?? '',
      totalCaseCount: int.parse(payload['totalCaseCount'] ?? '0'),
      activeCaseCount: int.parse(payload['activeCaseCount'] ?? '0'),
      followUpScheduledCount: int.parse(payload['followUpScheduledCount'] ?? '0'),
      followUpCompletedCount: int.parse(payload['followUpCompletedCount'] ?? '0'),
      closedCaseCount: int.parse(payload['closedCaseCount'] ?? '0'),
    );
  }

  static String reportIdFrom(Map<String, String> payload) =>
      payload['reportId'] ?? '';
}
