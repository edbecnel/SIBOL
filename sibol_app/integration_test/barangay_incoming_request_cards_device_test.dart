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

  const expectedEmails = <String>[
    'teen.demo@sibol.local',
    'teen.qa03@example.com',
  ];

  const displayNamesNotOnCards = <String>[
    'Demo Teen User',
    'QA Teen 03',
  ];

  testWidgets('Incoming request cards show account email (device, online)', (
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
    await tester.pumpAndSettle(const Duration(seconds: 15));

    expect(find.text('Barangay dashboard'), findsOneWidget);

    final container = ProviderScope.containerOf(
      tester.element(find.byType(SibolApp)),
    );
    container.read(appRouterProvider).go(Routes.barangayIncomingRequests);
    await tester.pumpAndSettle(const Duration(seconds: 12));

    expect(find.text('Incoming requests'), findsOneWidget);

    for (final email in expectedEmails) {
      expect(
        find.text(
          assistanceIncomingRequestCardAccountEmailLine(email),
        ),
        findsWidgets,
      );
    }

    for (final name in displayNamesNotOnCards) {
      expect(find.text(name), findsNothing);
    }

    expect(find.textContaining('Ref: demo-assist-inbox-001'), findsOneWidget);
    expect(find.textContaining('Ref: 32sQiFj9v8T6R6T3Asih'), findsOneWidget);
    expect(find.textContaining('Ref: qutPBKPACUfNAGY2ZidS'), findsOneWidget);

    container.read(appRouterProvider).go(
      Routes.barangayIncomingRequestDetail('demo-assist-inbox-001'),
    );
    await tester.pumpAndSettle(const Duration(seconds: 8));
    expect(find.text('Demo Teen User'), findsOneWidget);
    expect(find.text('teen.demo@sibol.local'), findsWidgets);
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
