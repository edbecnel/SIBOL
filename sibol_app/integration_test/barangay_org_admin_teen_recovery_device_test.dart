// Manual / PO-authorized device verification only. Requires an explicit password
// dart-define; do not run in CI or without authorized credentials.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:sibol_app/main_common.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  const password = String.fromEnvironment(
    'SIBOL_DEVICE_TEST_BARANGAY_ORG_ADMIN_PASSWORD',
  );

  testWidgets('Barangay org admin sees teen recovery and opens list (device)', (
    tester,
  ) async {
    if (password.isEmpty) {
      fail(
        'SIBOL_DEVICE_TEST_BARANGAY_ORG_ADMIN_PASSWORD dart-define is required.',
      );
    }

    await mainCommon();
    await tester.pumpAndSettle(const Duration(seconds: 15));

    await _signInOrgAdmin(tester, password);
    await tester.pumpAndSettle(const Duration(seconds: 20));

    expect(find.text('Barangay dashboard'), findsOneWidget,
        reason: 'Expected barangay.org.admin@sibol.local to reach dashboard');
    expect(find.text('Teen account recovery'), findsWidgets);

    await tester.tap(find.text('Teen account recovery').first);
    await tester.pumpAndSettle(const Duration(seconds: 15));

    expect(find.textContaining('Teen account recovery'), findsWidgets);
    expect(
      find.textContaining('You do not have permission'),
      findsNothing,
    );
  });
}

Future<void> _signOutIfNeeded(WidgetTester tester) async {
  final settings = find.byIcon(Icons.settings);
  if (settings.evaluate().isEmpty) return;
  await tester.tap(settings.first);
  await tester.pumpAndSettle(const Duration(seconds: 4));
  final signOut = find.text('Sign out');
  if (signOut.evaluate().isEmpty) return;
  await tester.tap(signOut);
  await tester.pumpAndSettle(const Duration(seconds: 8));
}

Future<void> _signInOrgAdmin(WidgetTester tester, String password) async {
  if (find.text('Teen account recovery').evaluate().isNotEmpty &&
      find.text('Barangay dashboard').evaluate().isNotEmpty) {
    return;
  }

  if (find.text('Barangay dashboard').evaluate().isNotEmpty) {
    await _signOutIfNeeded(tester);
  }

  if (find.text('Welcome to SIBOL').evaluate().isNotEmpty ||
      find.textContaining('Welcome').evaluate().isNotEmpty) {
    final welcomeSignIn = find.widgetWithText(ElevatedButton, 'Sign in');
    if (welcomeSignIn.evaluate().isNotEmpty) {
      await tester.tap(welcomeSignIn.first);
    } else {
      await tester.tap(find.text('Sign in').first);
    }
    await tester.pumpAndSettle(const Duration(seconds: 4));
  }

  final emailField = find.byWidgetPredicate(
    (w) => w is TextField && w.decoration?.labelText == 'Email',
  );
  if (emailField.evaluate().isEmpty) {
    return;
  }

  await tester.enterText(emailField, 'barangay.org.admin@sibol.local');

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
  await tester.pumpAndSettle(const Duration(seconds: 12));
}
