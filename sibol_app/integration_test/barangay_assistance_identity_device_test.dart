import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:sibol_app/app.dart';
import 'package:sibol_app/core/constants/route_constants.dart';
import 'package:sibol_app/core/router/app_router.dart';
import 'package:sibol_app/features/teenager/domain/assistance_request_submitter_identity.dart';
import 'package:sibol_app/main_common.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  const barangayPassword = String.fromEnvironment(
    'SIBOL_DEVICE_TEST_BARANGAY_PASSWORD',
  );

  const cases = <List<String>>[
    ['demo-assist-inbox-001', 'Demo Teen User', 'teen.demo@sibol.local'],
    ['32sQiFj9v8T6R6T3Asih', 'QA Teen 03', 'teen.qa03@example.com'],
    ['qutPBKPACUfNAGY2ZidS', 'QA Teen 03', 'teen.qa03@example.com'],
  ];

  testWidgets('Barangay request detail shows submitter identity (device)', (
    tester,
  ) async {
    if (barangayPassword.isEmpty) {
      fail(
        'SIBOL_DEVICE_TEST_BARANGAY_PASSWORD dart-define is required for device test.',
      );
    }

    await mainCommon();
    await tester.pumpAndSettle(const Duration(seconds: 15));

    await _signInBarangay(tester, barangayPassword);
    await tester.pumpAndSettle(const Duration(seconds: 10));

    final container = ProviderScope.containerOf(
      tester.element(find.byType(SibolApp)),
    );
    final router = container.read(appRouterProvider);

    for (final row in cases) {
      final requestId = row[0];
      final displayName = row[1];
      final email = row[2];
      router.go(Routes.barangayIncomingRequestDetail(requestId));
      await tester.pumpAndSettle(const Duration(seconds: 8));

      expect(find.text('Request details'), findsOneWidget);
      expect(
        find.text(AssistanceRequestSubmitterIdentityLabels.submittedBy),
        findsOneWidget,
      );
      expect(
        find.text(AssistanceRequestSubmitterIdentityLabels.accountEmail),
        findsOneWidget,
      );
      expect(find.text(displayName), findsOneWidget);
      expect(find.text(email), findsOneWidget);
      expect(
        find.text(AssistanceRequestSubmitterIdentityLabels.unavailable),
        findsNothing,
      );
    }
  });
}

Future<void> _signInBarangay(WidgetTester tester, String password) async {
  if (find.text('Sign in').evaluate().length > 1 ||
      find.textContaining('Sign in').evaluate().isNotEmpty) {
    final welcomeSignIn = find.widgetWithText(TextButton, 'Sign in');
    if (welcomeSignIn.evaluate().isNotEmpty) {
      await tester.tap(welcomeSignIn.first);
      await tester.pumpAndSettle();
    }
  }

  final emailField = find.byWidgetPredicate(
    (w) => w is TextField && w.decoration?.labelText == 'Email',
  );
  if (emailField.evaluate().isEmpty) {
    return;
  }

  await tester.enterText(emailField, 'barangay.demo@sibol.local');
  final passwordField = find.byWidgetPredicate(
    (w) => w is TextField && w.decoration?.labelText == 'Password',
  );
  await tester.enterText(passwordField, password);

  final submit = find.widgetWithText(ElevatedButton, 'Sign in');
  if (submit.evaluate().isEmpty) {
    final alt = find.text('Sign in');
    await tester.tap(alt.last);
  } else {
    await tester.tap(submit);
  }
  await tester.pumpAndSettle(const Duration(seconds: 12));
}
