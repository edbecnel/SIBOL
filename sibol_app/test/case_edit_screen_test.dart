import 'package:flutter_test/flutter_test.dart';
import 'package:sibol_app/features/cases/data/models/case_record_model.dart';
import 'package:sibol_app/features/cases/domain/case_completeness.dart';
import 'package:sibol_app/features/cases/domain/case_status.dart';
import 'package:sibol_app/features/cases/domain/case_subject_kind.dart';
import 'package:sibol_app/features/cases/domain/entities/case_record.dart';
import 'package:sibol_app/features/reporting/domain/report_status.dart';

void main() {
  test('active unregistered case serializes extended identity fields', () {
    final record = CaseRecord(
      caseId: 'case-new-1',
      demoName: 'Fictional Teen',
      fullName: 'Fictional Teen',
      age: 16,
      barangay: 'Barangay 3, Balingasag',
      orgId: 'barangay03',
      caseStatus: CaseStatus.active,
      registeredAt: DateTime.utc(2026, 4, 1),
      createdAt: DateTime.utc(2026, 4, 1),
      updatedAt: DateTime.utc(2026, 4, 1),
      reportStatus: ReportStatus.notSubmitted,
      subjectKind: CaseSubjectKind.unregistered,
      caseCompleteness: CaseCompleteness.active,
      dateOfBirth: '2009-06-01',
      contactEmail: 'fictional.teen@sibol.local',
    );
    final map = CaseRecordModel.fromEntity(record).toFirestoreMap();
    expect(map['subjectKind'], 'unregistered');
    expect(map['caseCompleteness'], 'active');
    expect(map['dateOfBirth'], '2009-06-01');
    expect(map['contactEmail'], 'fictional.teen@sibol.local');
  });
}
