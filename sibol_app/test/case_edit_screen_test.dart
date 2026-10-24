import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:sibol_app/core/providers/firebase_providers.dart';
import 'package:sibol_app/features/cases/presentation/screens/case_edit_screen.dart';
import 'package:sibol_app/features/org/presentation/providers/org_context_providers.dart';
import 'support/fake_case_repository.dart';

const _testOrgId = 'barangay03';

void main() {
  testWidgets('create screen validates empty demo name', (tester) async {
    final repo = FakeCaseRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          caseRepositoryProvider.overrideWithValue(repo),
          barangayCaseOrgIdProvider.overrideWithValue(_testOrgId),
        ],
        child: const MaterialApp(home: CaseEditScreen()),
      ),
    );

    await tester.tap(find.text('Create case'));
    await tester.pump();

    expect(find.textContaining('Demo name is required'), findsOneWidget);
  });

  testWidgets('create screen submits valid fictional case', (tester) async {
    final repo = FakeCaseRepository();

    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const CaseEditScreen(),
        ),
        GoRoute(
          path: '/barangay/cases/:caseId',
          builder: (context, state) => const Scaffold(body: Text('detail')),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          caseRepositoryProvider.overrideWithValue(repo),
          barangayCaseOrgIdProvider.overrideWithValue(_testOrgId),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );

    await tester.enterText(find.widgetWithText(TextField, 'Demo name'), 'New Demo');
    await tester.enterText(find.widgetWithText(TextField, 'Age (13–19)'), '17');
    await tester.enterText(find.widgetWithText(TextField, 'Barangay'), 'Demo Barangay');
    await tester.tap(find.text('Create case'));
    await tester.pumpAndSettle();

    final cases = await repo.fetchCasesForOrg(_testOrgId);
    expect(cases.length, 1);
    expect(cases.first.demoName, 'New Demo');
  });
}
