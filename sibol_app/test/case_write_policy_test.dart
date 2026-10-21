import 'package:flutter_test/flutter_test.dart';
import 'package:sibol_app/features/cases/domain/case_status.dart';
import 'package:sibol_app/features/cases/domain/case_write_policy.dart';
import 'package:sibol_app/features/cases/domain/entities/case_record.dart';
import 'package:sibol_app/features/reporting/domain/report_status.dart';

CaseRecord _record({
  String caseId = 'c1',
  ReportStatus reportStatus = ReportStatus.notSubmitted,
  DateTime? createdAt,
}) {
  final created = createdAt ?? DateTime(2026, 1, 1);
  return CaseRecord(
    caseId: caseId,
    demoName: 'Ana Demo',
    age: 16,
    barangay: 'Demo',
    caseStatus: CaseStatus.active,
    registeredAt: created,
    createdAt: created,
    updatedAt: created,
    reportStatus: reportStatus,
  );
}

void main() {
  test('create requires notSubmitted report status', () {
    expect(
      CaseWritePolicy.validateForCreate(
        _record(reportStatus: ReportStatus.pendingSubmit),
      ),
      isNotNull,
    );
    expect(CaseWritePolicy.validateForCreate(_record()), isNull);
  });

  test('update forbids reportStatus and createdAt changes', () {
    final existing = _record();
    final badReport = _record(reportStatus: ReportStatus.pendingSubmit);
    expect(
      CaseWritePolicy.validateForUpdate(updated: badReport, existing: existing),
      isNotNull,
    );
    final badCreated = _record(createdAt: DateTime(2025));
    expect(
      CaseWritePolicy.validateForUpdate(
        updated: badCreated,
        existing: existing,
      ),
      isNotNull,
    );
    final ok = CaseRecord(
      caseId: existing.caseId,
      demoName: 'Updated Name',
      age: existing.age,
      barangay: existing.barangay,
      caseStatus: existing.caseStatus,
      registeredAt: existing.registeredAt,
      createdAt: existing.createdAt,
      updatedAt: DateTime(2026, 2, 1),
      reportStatus: existing.reportStatus,
    );
    expect(
      CaseWritePolicy.validateForUpdate(updated: ok, existing: existing),
      isNull,
    );
  });
}
