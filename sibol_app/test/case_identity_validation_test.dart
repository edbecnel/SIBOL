import 'package:flutter_test/flutter_test.dart';
import 'package:sibol_app/features/cases/domain/case_completeness.dart';
import 'package:sibol_app/features/cases/domain/case_contact_validation.dart';
import 'package:sibol_app/features/cases/domain/case_status.dart';
import 'package:sibol_app/features/cases/domain/case_subject_kind.dart';
import 'package:sibol_app/features/cases/domain/case_validation.dart';
import 'package:sibol_app/features/cases/domain/entities/case_record.dart';
import 'package:sibol_app/features/reporting/domain/report_status.dart';

void main() {
  test('requires contact for active case', () {
    final record = CaseRecord(
      caseId: 'c1',
      demoName: 'Fictional Teen',
      fullName: 'Fictional Teen',
      age: 16,
      barangay: 'Barangay 3, Balingasag',
      orgId: 'barangay03',
      caseStatus: CaseStatus.active,
      registeredAt: DateTime(2026, 1, 1),
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
      subjectKind: CaseSubjectKind.unregistered,
      caseCompleteness: CaseCompleteness.active,
      dateOfBirth: '2009-06-01',
    );
    expect(CaseValidation.validateActiveCase(record), isNotNull);
    expect(
      CaseContactValidation.hasContactMethod(
        contactEmail: 'teen.fictional@sibol.local',
      ),
      isTrue,
    );
  });

  test('draft allows missing contact', () {
    final record = CaseRecord(
      caseId: 'c2',
      demoName: 'Draft Teen',
      fullName: 'Draft Teen',
      age: 0,
      barangay: 'Barangay 3, Balingasag',
      orgId: 'barangay03',
      caseStatus: CaseStatus.active,
      registeredAt: DateTime(2026, 1, 1),
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
      caseCompleteness: CaseCompleteness.draft,
    );
    expect(CaseValidation.validateDraft(record), isNull);
  });
}
