import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sibol_app/core/providers/firebase_providers.dart';
import 'package:sibol_app/features/cases/domain/entities/case_record.dart';
import 'package:sibol_app/features/cases/presentation/screens/case_detail_screen.dart';
import 'support/fake_case_repository.dart';
import 'support/sample_case_records.dart';

void main() {
  testWidgets('shows loading then case fields (read-only)', (tester) async {
    final record = sampleCaseRecord();
    final repo = FakeCaseRepository(
      caseStreams: {
        record.caseId: Stream.value(record),
      },
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          caseRepositoryProvider.overrideWithValue(repo),
        ],
        child: MaterialApp(
          home: CaseDetailScreen(caseId: record.caseId),
        ),
      ),
    );

    expect(find.text('Loading case…'), findsOneWidget);
    await tester.pumpAndSettle();

    expect(find.text('Bea Demo Santos'), findsOneWidget);
    expect(find.text('demo-case-001'), findsOneWidget);
    expect(find.text('Fictional demonstration case for academic review.'),
        findsOneWidget);
    expect(find.byType(TextField), findsNothing);
  });

  testWidgets('shows not-found message when case is missing', (tester) async {
    final repo = FakeCaseRepository(
      caseStreams: {'missing-id': Stream<CaseRecord?>.value(null)},
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          caseRepositoryProvider.overrideWithValue(repo),
        ],
        child: MaterialApp(
          home: const CaseDetailScreen(caseId: 'missing-id'),
        ),
      ),
    );
    await tester.pump();

    expect(
      find.textContaining('not found'),
      findsOneWidget,
    );
  });

  testWidgets('shows error widget when stream fails', (tester) async {
    final repo = FakeCaseRepository(
      caseStreams: {
        'err': Stream<CaseRecord?>.error(Exception('permission denied')),
      },
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          caseRepositoryProvider.overrideWithValue(repo),
        ],
        child: MaterialApp(
          home: const CaseDetailScreen(caseId: 'err'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Could not load this case'), findsOneWidget);
  });

  testWidgets('displays dash for empty optional text fields', (tester) async {
    final base = sampleCaseRecord();
    final record = CaseRecord(
      caseId: base.caseId,
      demoName: base.demoName,
      age: base.age,
      barangay: base.barangay,
      orgId: base.orgId,
      caseStatus: base.caseStatus,
      registeredAt: base.registeredAt,
      nextFollowUpAt: base.nextFollowUpAt,
      notes: '',
      createdAt: base.createdAt,
      updatedAt: base.updatedAt,
      reportStatus: base.reportStatus,
    );
    final repo = FakeCaseRepository(
      caseStreams: {record.caseId: Stream.value(record)},
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          caseRepositoryProvider.overrideWithValue(repo),
        ],
        child: MaterialApp(
          home: CaseDetailScreen(caseId: record.caseId),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('—'), findsWidgets);
  });
}
