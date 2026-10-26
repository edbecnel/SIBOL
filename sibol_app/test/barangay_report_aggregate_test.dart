import 'package:flutter_test/flutter_test.dart';
import 'package:sibol_app/features/cases/domain/case_status.dart';
import 'package:sibol_app/features/cases/domain/entities/case_record.dart';
import 'package:sibol_app/features/reporting/domain/barangay_report_aggregate.dart';
import 'package:sibol_app/features/reporting/domain/report_status.dart';

void main() {
  final now = DateTime(2026, 10, 21);

  CaseRecord caseAt(
    String id,
    String barangay,
    CaseStatus status, {
    String orgId = 'barangay03',
  }) {
    return CaseRecord(
      caseId: id,
      demoName: 'Demo $id',
      age: 16,
      barangay: barangay,
      orgId: orgId,
      caseStatus: status,
      registeredAt: now,
      createdAt: now,
      updatedAt: now,
      reportStatus: ReportStatus.notSubmitted,
    );
  }

  test('computeBarangayReportAggregate scopes by orgId and counts statuses', () {
    const orgId = 'barangay03';
    const reportingLabel = 'Barangay 3, Balingasag';
    final cases = [
      caseAt('1', 'Barangay 3, Balingasag', CaseStatus.active),
      caseAt('2', 'Barangay 3, Balingasag', CaseStatus.followUpScheduled),
      caseAt('3', 'Other site', CaseStatus.closed, orgId: 'other'),
    ];

    final counts = computeBarangayReportAggregate(
      cases: cases,
      orgId: orgId,
      barangay: reportingLabel,
    );

    expect(counts.totalCaseCount, 2);
    expect(counts.activeCaseCount, 1);
    expect(counts.followUpScheduledCount, 1);
    expect(counts.closedCaseCount, 0);
    expect(counts.barangay, reportingLabel);
  });
}
