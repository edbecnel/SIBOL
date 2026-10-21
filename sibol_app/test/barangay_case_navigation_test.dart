import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:sibol_app/core/constants/route_constants.dart';
import 'package:sibol_app/core/providers/firebase_providers.dart';
import 'package:sibol_app/features/cases/presentation/screens/barangay_home_screen.dart';
import 'package:sibol_app/features/cases/presentation/screens/case_detail_screen.dart';
import 'support/fake_case_repository.dart';
import 'support/sample_case_records.dart';

void main() {
  testWidgets('tapping a case opens read-only detail route', (tester) async {
    final record = sampleCaseRecord();
    final repo = FakeCaseRepository(
      cases: [record],
      caseStreams: {
        record.caseId: Stream.value(record),
      },
    );

    final router = GoRouter(
      initialLocation: Routes.barangayHome,
      routes: [
        GoRoute(
          path: Routes.barangayHome,
          builder: (context, state) => const BarangayHomeScreen(),
          routes: [
            GoRoute(
              path: '${Routes.barangayCaseSegment}/:caseId',
              builder: (context, state) {
                final caseId = state.pathParameters['caseId']!;
                return CaseDetailScreen(caseId: caseId);
              },
            ),
          ],
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          caseRepositoryProvider.overrideWithValue(repo),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pump();

    expect(find.text('Bea Demo Santos'), findsOneWidget);
    await tester.tap(find.text('Bea Demo Santos'));
    await tester.pumpAndSettle();

    expect(find.text('Case details'), findsOneWidget);
    expect(find.text('demo-case-001'), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
  });
}
