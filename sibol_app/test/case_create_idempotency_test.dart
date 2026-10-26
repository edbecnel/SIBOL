import 'package:flutter_test/flutter_test.dart';
import 'package:sibol_app/features/cases/domain/case_status.dart';
import 'package:sibol_app/features/cases/domain/entities/case_record.dart';
import 'package:sibol_app/features/reporting/domain/report_status.dart';
import 'support/fake_case_repository.dart';

void main() {
  test('createCase with same document id does not duplicate in fake repository',
      () async {
    final repo = FakeCaseRepository();
    final id = repo.newCaseDocumentId();
    final record = CaseRecord(
      caseId: id,
      demoName: 'Maria Offline Test',
      age: 16,
      barangay: 'Barangay 3, Balingasag',
      orgId: 'barangay03',
      caseStatus: CaseStatus.active,
      registeredAt: DateTime.utc(2026, 4, 1),
      notes: 'Offline QA',
      createdAt: DateTime.utc(2026, 4, 1),
      updatedAt: DateTime.utc(2026, 4, 1),
      reportStatus: ReportStatus.notSubmitted,
    );
    expect(await repo.createCase(record), id);
    expect(await repo.createCase(record), id);
    final cases = await repo.fetchCasesForOrg('barangay03');
    expect(cases.where((c) => c.demoName == 'Maria Offline Test').length, 1);
  });
}
