import 'package:flutter_test/flutter_test.dart';
import 'package:sibol_app/features/cases/domain/case_status.dart';
import 'package:sibol_app/features/cases/domain/entities/case_record.dart';
import 'package:sibol_app/features/reporting/domain/barangay_report_aggregate.dart';
import 'package:sibol_app/features/reporting/domain/report_status.dart';

void main() {
  final now = DateTime(2026, 10, 21);

  CaseRecord caseAt(String id, String barangay, CaseStatus status) {
    return CaseRecord(
      caseId: id,
      demoName: 'Demo $id',
      age: 16,
      barangay: barangay,
      orgId: 'barangay03',
      caseStatus: status,
      registeredAt: now,
      createdAt: now,
      updatedAt: now,
      reportStatus: ReportStatus.notSubmitted,
    );
  }

  test('computeBarangayReportAggregate scopes by barangay and counts statuses', () {
    final site = 'Barangay Tres, Balingasag';
    final cases = [
      caseAt('1', site, CaseStatus.active),
      caseAt('2', site, CaseStatus.followUpScheduled),
      caseAt('3', 'Other site', CaseStatus.closed),
    ];

    final counts = computeBarangayReportAggregate(cases: cases, barangay: site);

    expect(counts.totalCaseCount, 2);
    expect(counts.activeCaseCount, 1);
    expect(counts.followUpScheduledCount, 1);
    expect(counts.closedCaseCount, 0);
  });
}
