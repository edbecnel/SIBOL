import 'package:flutter_test/flutter_test.dart';
import 'package:sibol_app/features/cases/domain/case_status.dart';
import 'package:sibol_app/features/cases/domain/case_validation.dart';
import 'package:sibol_app/features/cases/domain/entities/case_record.dart';
import 'package:sibol_app/features/cases/data/models/case_record_model.dart';
import 'package:sibol_app/features/reporting/domain/report_status.dart';

void main() {
  group('CaseValidation', () {
    test('rejects age outside 13-19', () {
      expect(CaseValidation.validateAge(12), isNotNull);
      expect(CaseValidation.validateAge(20), isNotNull);
      expect(CaseValidation.validateAge(16), isNull);
    });

    test('rejects empty demo name', () {
      expect(CaseValidation.validateDemoName(''), isNotNull);
      expect(CaseValidation.validateDemoName('Ana Demo'), isNull);
    });
  });

  group('CaseRecordModel.assertValidForWrite', () {
    test('accepts valid fictional record', () {
      final record = CaseRecord(
        caseId: 'x',
        demoName: 'Ana Demo',
        age: 16,
        barangay: 'Barangay 3, Balingasag',
        orgId: 'barangay03',
        caseStatus: CaseStatus.active,
        registeredAt: DateTime(2026, 10, 1),
        createdAt: DateTime(2026, 10, 1),
        updatedAt: DateTime(2026, 10, 1),
        reportStatus: ReportStatus.notSubmitted,
      );
      expect(() => CaseRecordModel.assertValidForWrite(record), returnsNormally);
    });
  });
}
