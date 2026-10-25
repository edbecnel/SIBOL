import 'package:flutter_test/flutter_test.dart';
import 'package:sibol_app/features/reporting/domain/barangay_report_aggregate.dart';
import 'package:sibol_app/features/reporting/domain/barangay_report_queue_payload.dart';

void main() {
  test('report queue payload preserves frozen counts', () {
    const counts = BarangayReportAggregateCounts(
      barangay: 'Demo Barangay',
      totalCaseCount: 4,
      activeCaseCount: 2,
      followUpScheduledCount: 1,
      followUpCompletedCount: 0,
      closedCaseCount: 1,
    );
    final payload = BarangayReportQueuePayload.encode(
      reportId: 'rpt-abc',
      orgId: 'org-1',
      submittedByUid: 'uid-1',
      counts: counts,
    );
    expect(BarangayReportQueuePayload.reportIdFrom(payload), 'rpt-abc');
    final restored = BarangayReportQueuePayload.countsFrom(payload);
    expect(restored.totalCaseCount, 4);
    expect(restored.activeCaseCount, 2);
    expect(restored.barangay, 'Demo Barangay');
  });
}
