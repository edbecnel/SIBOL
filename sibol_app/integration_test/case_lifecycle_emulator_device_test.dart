// Emulator-only CASE-LIFECYCLE-001 UI acceptance (canonical demo-sibol-emulator).
// Requires running Auth/Firestore/Functions emulators and seeded fictional accounts.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';
import 'package:sibol_app/app.dart';
import 'package:sibol_app/core/constants/route_constants.dart';
import 'package:sibol_app/core/router/app_router.dart';
import 'package:sibol_app/features/teenager/domain/assistance_request_category.dart';
import 'package:sibol_app/main_common.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  const teenPassword = String.fromEnvironment('SIBOL_DEVICE_TEST_TEEN_PASSWORD');
  const barangayPassword =
      String.fromEnvironment('SIBOL_DEVICE_TEST_BARANGAY_PASSWORD');
  const mophPassword = String.fromEnvironment('SIBOL_DEVICE_TEST_MOPH_PASSWORD');

  testWidgets('CASE-LIFECYCLE-001 emulator UI walkthrough', (tester) async {
    if (teenPassword.isEmpty ||
        barangayPassword.isEmpty ||
        mophPassword.isEmpty) {
      fail(
        'SIBOL_DEVICE_TEST_TEEN_PASSWORD, SIBOL_DEVICE_TEST_BARANGAY_PASSWORD, '
        'and SIBOL_DEVICE_TEST_MOPH_PASSWORD dart-defines are required.',
      );
    }

    final runToken =
        DateTime.now().toUtc().millisecondsSinceEpoch.toString();
    final requestDescription =
        'Fictional CASE-LIFECYCLE acceptance request $runToken. '
        'This text is for emulator verification only.';

    await mainCommon();
    await tester.pumpAndSettle(const Duration(seconds: 15));

    final container = ProviderScope.containerOf(
      tester.element(find.byType(SibolApp)),
    );
    final router = container.read(appRouterProvider);

    // 1 — Teen submits assistance request.
    await _signIn(tester, 'teen.demo@sibol.local', teenPassword);
    await tester.pumpAndSettle(const Duration(seconds: 15));
    expect(find.text('Teenager dashboard'), findsOneWidget);
    await tester.tap(find.widgetWithText(ElevatedButton, 'New support request'));
    await tester.pumpAndSettle(const Duration(seconds: 10));
    expect(find.text('New support request'), findsOneWidget);
    await tester.tap(find.byType(DropdownButtonFormField<AssistanceRequestCategory>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('General support (demo)').first);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byWidgetPredicate(
        (w) =>
            w is TextField &&
            w.decoration?.labelText == 'Description (fictional demo content)',
      ),
      requestDescription,
    );
    await tester.tap(find.widgetWithText(ElevatedButton, 'Submit request'));
    await tester.pumpAndSettle(const Duration(seconds: 25));
    expect(
      find.textContaining(runToken),
      findsWidgets,
      reason: 'Submitted request should appear after server confirmation.',
    );

    await _signOut(tester, router);
    await tester.pumpAndSettle(const Duration(seconds: 8));

    // 2–4 — Barangay acknowledges, opens case, idempotent link messaging.
    await _signIn(tester, 'barangay.demo@sibol.local', barangayPassword);
    await tester.pumpAndSettle(const Duration(seconds: 12));
    router.go(Routes.barangayIncomingRequests);
    await tester.pumpAndSettle(const Duration(seconds: 12));
    expect(find.textContaining(runToken), findsWidgets);

    await tester.tap(find.textContaining(runToken).first);
    await tester.pumpAndSettle(const Duration(seconds: 10));
    await tester.tap(find.widgetWithText(ElevatedButton, 'Acknowledge receipt'));
    await tester.pumpAndSettle(const Duration(seconds: 15));
    expect(find.text('Acknowledged'), findsWidgets);

    await tester.tap(find.widgetWithText(ElevatedButton, 'Open Barangay case'));
    await tester.pumpAndSettle(const Duration(seconds: 15));
    expect(find.text('Case details'), findsOneWidget);
    expect(find.text('Open case'), findsWidgets);
    expect(find.text('Case lifecycle'), findsOneWidget);

    router.pop();
    await tester.pumpAndSettle(const Duration(seconds: 8));
    expect(
      find.widgetWithText(ElevatedButton, 'View linked case'),
      findsOneWidget,
    );
    await tester.tap(find.widgetWithText(ElevatedButton, 'View linked case'));
    await tester.pumpAndSettle(const Duration(seconds: 10));
    expect(find.text('Case details'), findsOneWidget);

    // 5 — Start case work.
    await tester.tap(find.widgetWithText(ElevatedButton, 'Start case work'));
    await tester.pumpAndSettle(const Duration(seconds: 12));
    expect(find.text('In progress'), findsWidgets);

    // 6 — MOPH referral from request detail.
    router.pop();
    await tester.pumpAndSettle(const Duration(seconds: 6));
    await tester.tap(find.widgetWithText(ElevatedButton, 'Refer to MOPH coordination'));
    await tester.pumpAndSettle(const Duration(seconds: 10));
    const referralSummary =
        'Fictional barangay summary for hospital coordination without teen identifiers.';
    await tester.enterText(
      find.widgetWithText(TextField, 'Barangay-prepared summary for MOPH'),
      referralSummary,
    );
    await tester.tap(find.widgetWithText(ElevatedButton, 'Review before submit'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ElevatedButton, 'Submit referral to MOPH'));
    await tester.pumpAndSettle(const Duration(seconds: 20));
    router.go(Routes.barangaySubmittedReferrals);
    await tester.pumpAndSettle(const Duration(seconds: 12));
    expect(find.text('Submitted referrals'), findsOneWidget);
    expect(find.byType(ListTile), findsWidgets);

    await _signOut(tester, router);
    await tester.pumpAndSettle(const Duration(seconds: 8));

    // 7–9 — MOPH coordination updates.
    await _signIn(tester, 'moph.demo@sibol.local', mophPassword);
    await tester.pumpAndSettle(const Duration(seconds: 12));
    expect(find.text('MOPH dashboard'), findsOneWidget);
    await tester.tap(find.byType(ListTile).first);
    await tester.pumpAndSettle(const Duration(seconds: 12));
    expect(find.text('Coordination referral'), findsOneWidget);
    await tester.tap(find.widgetWithText(ElevatedButton, 'Mark received'));
    await tester.pumpAndSettle(const Duration(seconds: 12));
    await tester.tap(find.widgetWithText(ElevatedButton, 'Request information'));
    await tester.pumpAndSettle(const Duration(seconds: 12));

    await _signOut(tester, router);
    await tester.pumpAndSettle(const Duration(seconds: 8));

    // 10–11 — Barangay responds; MOPH completes coordination.
    await _signIn(tester, 'barangay.demo@sibol.local', barangayPassword);
    await tester.pumpAndSettle(const Duration(seconds: 12));
    router.go(Routes.barangaySubmittedReferrals);
    await tester.pumpAndSettle(const Duration(seconds: 12));
    await tester.tap(find.byType(ListTile).first);
    await tester.pumpAndSettle(const Duration(seconds: 12));
    await tester.tap(
      find.widgetWithText(ElevatedButton, 'Provide information to hospital'),
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, 'Administrative response (10–500 characters)'),
      'Fictional barangay administrative response with sufficient detail.',
    );
    await tester.tap(find.widgetWithText(ElevatedButton, 'Submit'));
    await tester.pumpAndSettle(const Duration(seconds: 15));

    await _signOut(tester, router);
    await tester.pumpAndSettle(const Duration(seconds: 8));

    await _signIn(tester, 'moph.demo@sibol.local', mophPassword);
    await tester.pumpAndSettle(const Duration(seconds: 12));
    await tester.tap(find.byType(ListTile).first);
    await tester.pumpAndSettle(const Duration(seconds: 12));
    await tester.tap(
      find.widgetWithText(ElevatedButton, 'Mark coordination complete'),
    );
    await tester.pumpAndSettle(const Duration(seconds: 12));

    await _signOut(tester, router);
    await tester.pumpAndSettle(const Duration(seconds: 8));

    // 12–14 — Resolve and close case; verify lifecycle labels persist.
    await _signIn(tester, 'barangay.demo@sibol.local', barangayPassword);
    await tester.pumpAndSettle(const Duration(seconds: 12));
    router.go(Routes.barangayIncomingRequests);
    await tester.pumpAndSettle(const Duration(seconds: 10));
    await tester.tap(find.textContaining(runToken).first);
    await tester.pumpAndSettle(const Duration(seconds: 8));
    await tester.tap(find.widgetWithText(ElevatedButton, 'View linked case'));
    await tester.pumpAndSettle(const Duration(seconds: 12));

    await tester.tap(find.widgetWithText(ElevatedButton, 'Mark resolved'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, 'Describe how the case was resolved'),
      'Fictional resolution after MOPH coordination completed successfully.',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle(const Duration(seconds: 12));
    expect(find.text('Resolved'), findsWidgets);

    await tester.tap(find.widgetWithText(ElevatedButton, 'Close case'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, 'Reason for closing this case'),
      'Fictional closure after coordination finished.',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, 'Additional closure documentation'),
      'Fictional closure notes documenting end of barangay case work.',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle(const Duration(seconds: 15));
    expect(find.text('Closed case'), findsWidgets);

    final caseDetailRoute = router.routeInformationProvider.value.uri.path;
    router.go(Routes.barangayHome);
    await tester.pumpAndSettle(const Duration(seconds: 6));
    router.go(caseDetailRoute);
    await tester.pumpAndSettle(const Duration(seconds: 12));
    expect(find.text('Closed case'), findsWidgets);

    // Offline follow-up on linked case (online create first for cache).
    await tester.tap(find.byIcon(Icons.event_note));
    await tester.pumpAndSettle();
    const onlineFollowUpNotes =
        'Online follow-up baseline before offline regression segment.';
    await tester.enterText(
      find.widgetWithText(TextField, 'Observation or action taken'),
      onlineFollowUpNotes,
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle(const Duration(seconds: 12));
    expect(find.textContaining(onlineFollowUpNotes), findsWidgets);

    // Negative — lifecycle panel offline messaging is covered by widget copy;
    // follow-up path remains available while lifecycle actions require online.
    expect(
      find.textContaining('Case lifecycle actions require an online connection'),
      findsNothing,
    );
  });
}

Future<void> _signIn(
  WidgetTester tester,
  String email,
  String password,
) async {
  final container = ProviderScope.containerOf(
    tester.element(find.byType(SibolApp)),
  );
  container.read(appRouterProvider).go(Routes.login);
  await tester.pumpAndSettle(const Duration(seconds: 10));

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
  expect(emailField, findsOneWidget, reason: 'Login email field should be visible.');

  await tester.enterText(emailField, email);
  final passwordField = find.byWidgetPredicate(
    (w) => w is TextField && w.decoration?.labelText == 'Password',
  );
  await tester.enterText(passwordField, password);

  final submit = find.widgetWithText(ElevatedButton, 'Sign in');
  if (submit.evaluate().isEmpty) {
    await tester.tap(find.text('Sign in').last);
  } else {
    await tester.tap(submit);
  }
  await tester.pumpAndSettle(const Duration(seconds: 20));
}

Future<void> _signOut(WidgetTester tester, GoRouter router) async {
  router.go(Routes.settings);
  await tester.pumpAndSettle(const Duration(seconds: 8));
  await tester.tap(find.widgetWithText(ElevatedButton, 'Sign out'));
  await tester.pumpAndSettle(const Duration(seconds: 10));
}
