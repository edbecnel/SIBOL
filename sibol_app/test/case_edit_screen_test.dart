import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:sibol_app/core/providers/firebase_providers.dart';
import 'package:sibol_app/features/cases/presentation/screens/case_edit_screen.dart';
import 'package:sibol_app/features/auth/domain/entities/user_profile.dart';
import 'package:sibol_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:sibol_app/features/org/presentation/providers/org_context_providers.dart';
import 'package:sibol_app/core/permissions/sibol_role.dart';
import 'support/fake_case_repository.dart';

const _testOrgId = 'barangay03';
const _canonicalBarangay = 'Barangay 3, Balingasag';

UserProfile _barangayProfile() {
  return UserProfile(
    uid: 'barangay-1',
    role: SibolRole.barangay,
    displayName: 'Demo BNS',
    active: true,
    createdAt: DateTime.utc(2026, 1, 1),
    assignedBarangay: _canonicalBarangay,
    primaryOrgId: _testOrgId,
  );
}

void main() {
  testWidgets('create screen validates empty demo name', (tester) async {
    final repo = FakeCaseRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          caseRepositoryProvider.overrideWithValue(repo),
          barangayCaseOrgIdProvider.overrideWithValue(_testOrgId),
          userProfileProvider.overrideWith(
            (ref) => Stream.value(_barangayProfile()),
          ),
        ],
        child: const MaterialApp(home: CaseEditScreen()),
      ),
    );
    await tester.pumpAndSettle();

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
          userProfileProvider.overrideWith(
            (ref) => Stream.value(_barangayProfile()),
          ),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.widgetWithText(TextField, 'Demo name'), 'New Demo');
    await tester.enterText(find.widgetWithText(TextField, 'Age (13–19)'), '17');
    expect(find.text(_canonicalBarangay), findsOneWidget);
    await tester.tap(find.text('Create case'));
    await tester.pumpAndSettle();

    final cases = await repo.fetchCasesForOrg(_testOrgId);
    expect(cases.length, 1);
    expect(cases.first.demoName, 'New Demo');
    expect(cases.first.barangay, _canonicalBarangay);
  });
}
