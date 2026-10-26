import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sibol_app/core/providers/firebase_providers.dart';
import 'package:sibol_app/features/cases/domain/case_status.dart';
import 'package:sibol_app/features/cases/domain/entities/case_record.dart';
import 'package:sibol_app/features/cases/presentation/providers/case_providers.dart';
import 'package:sibol_app/features/cases/presentation/screens/case_edit_screen.dart';
import 'package:sibol_app/features/reporting/domain/report_status.dart';
import 'support/fake_case_repository.dart';

CaseRecord _mariaRecord() {
  return CaseRecord(
    caseId: 'fhcQrLxE0IhwPFzCPinH',
    demoName: 'Maria Offline Test',
    age: 16,
    barangay: 'Barangay 3, Balingasag',
    orgId: 'barangay03',
    caseStatus: CaseStatus.active,
    registeredAt: DateTime.utc(2026, 4, 1),
    notes: 'QA-OFFLINE-CASE-001',
    createdAt: DateTime.utc(2026, 4, 1),
    updatedAt: DateTime.utc(2026, 4, 1),
    reportStatus: ReportStatus.notSubmitted,
  );
}

void main() {
  testWidgets('edit screen shows cached case fields without server snapshot',
      (tester) async {
    final record = _mariaRecord();
    final repo = FakeCaseRepository(cases: [record]);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          caseRepositoryProvider.overrideWithValue(repo),
        ],
        child: MaterialApp(
          home: CaseEditScreen(caseId: record.caseId),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Edit case'), findsWidgets);
    expect(
      find.widgetWithText(TextField, 'Maria Offline Test'),
      findsOneWidget,
    );
    expect(find.textContaining('fhcQrLxE0IhwPFzCPinH'), findsOneWidget);
    expect(find.textContaining('Legacy record'), findsOneWidget);
  });

  testWidgets('edit screen shows recoverable error when case not cached',
      (tester) async {
    final repo = FakeCaseRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          caseRepositoryProvider.overrideWithValue(repo),
        ],
        child: const MaterialApp(
          home: CaseEditScreen(caseId: 'missing-case-id'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.textContaining('not available on this device'),
      findsOneWidget,
    );
  });
}
