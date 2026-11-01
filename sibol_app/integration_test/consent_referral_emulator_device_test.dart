import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:sibol_app/core/constants/route_constants.dart';
import 'package:sibol_app/features/disclosure/domain/disclosure_constants.dart';
import 'package:sibol_app/features/teenager/domain/assistance_request_category.dart';
import 'support/emulator_auth_harness.dart';
import 'support/emulator_test_bootstrap.dart';
import 'support/emulator_test_accounts.dart';
import 'support/wait_for_widget.dart';

/// SIBOL-CONSENT-REFERRAL-001 device acceptance (gate disabled — default build).
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  final credentials = EmulatorTestCredentials.fromEnvironment();
  const gateOn = DisclosureLegalPolicy.identifyingDisclosureActivated;

  testWidgets('consent referral coordination with declined authorization (gate off)', (
    tester,
  ) async {
    expect(
      gateOn,
      isFalse,
      reason: 'This test expects production-default legal gate disabled.',
    );

    final runToken =
        DateTime.now().toUtc().millisecondsSinceEpoch.toString();
    final requestDescription =
        'Fictional consent-referral acceptance $runToken. Emulator-only synthetic text.';

    await prepareEmulatorIntegrationSession(tester);
    final auth = harnessFor(tester);

    // Teen — submit assistance.
    await auth.signInAsTeenager(credentials.teenPassword);
    await tester.tap(primaryButton('New support request'));
    await pumpUntilFound(tester, find.text('New support request'));
    await tester.tap(find.byType(DropdownButtonFormField<AssistanceRequestCategory>));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.text('General support (demo)').first);
    await tester.pump(const Duration(milliseconds: 400));
    await tester.enterText(
      find.byWidgetPredicate(
        (w) =>
            w is TextField &&
            w.decoration?.labelText == 'Description (fictional demo content)',
      ),
      requestDescription,
    );
    await tester.tap(primaryButton('Submit request'));
    await pumpUntilFound(tester, find.textContaining(runToken));
    await auth.signOutCurrentUser();

    // Barangay — acknowledge + request disclosure authorization.
    await auth.signInAsBarangay(credentials.barangayPassword);
    auth.router.go(Routes.barangayIncomingRequests);
    await pumpUntilFound(tester, find.text('Incoming requests'));
    await tester.tap(find.textContaining(runToken).first);
    await pumpUntilFound(tester, find.text('MOPH disclosure authorization'));
    await tester.tap(primaryButton('Acknowledge receipt'));
    await pumpUntilFound(tester, find.text('Acknowledged'));
    await tester.tap(primaryButton('Request authorization'));
    await pumpUntilFound(
      tester,
      find.textContaining('Latest authorization status'),
    );
    await auth.signOutCurrentUser();

    // Teen — decline authorization (permitted without legal gate).
    await auth.signInAsTeenager(credentials.teenPassword);
    auth.router.go(Routes.teenAssistanceList);
    await pumpUntilFound(tester, find.text('My requests'));
    await tester.tap(find.textContaining(runToken).first);
    await pumpUntilFound(tester, find.text('Hospital disclosure authorization'));
    expect(find.textContaining('legal_name'), findsWidgets);
    await tester.tap(find.text('Decline'));
    await pumpUntilFound(tester, find.textContaining('Decision recorded: declined'));
    await auth.signOutCurrentUser();

    // Barangay — minimum structured referral after decline.
    await auth.signInAsBarangay(credentials.barangayPassword);
    auth.router.go(Routes.barangayIncomingRequests);
    await tester.tap(find.textContaining(runToken).first);
    await pumpUntilFound(
      tester,
      find.textContaining('Latest authorization status: declined'),
    );
    await tester.tap(primaryButton('Refer to MOPH coordination'));
    await pumpUntilFound(tester, find.text('Structured MOPH referral'));
    expect(find.text('Minimum'), findsWidgets);
    await tester.tap(primaryButton('Submit referral'));
    await pumpUntilFound(
      tester,
      find.text('MOPH coordination referral already submitted'),
    );
    await auth.signOutCurrentUser();

    // MOPH — inbox and coordination updates.
    await auth.signInAsMoph(credentials.mophPassword);
    await pumpUntilFound(tester, find.text('MOPH dashboard'));
    await tester.tap(find.byType(ListTile).first);
    await pumpUntilFound(tester, find.text('Coordination referral'));
    expect(find.text('Demo Teen User'), findsNothing);
    await tester.tap(primaryButton('Mark received'));
    await pumpUntilFound(tester, find.textContaining('Coordination status'));
    await tester.tap(primaryButton('Request information'));
    await auth.signOutCurrentUser();

    // Barangay — structured information response + case work.
    await auth.signInAsBarangay(credentials.barangayPassword);
    auth.router.go(Routes.barangayIncomingRequests);
    await tester.tap(find.textContaining(runToken).first);
    await tester.tap(primaryButton('Open Barangay case'));
    await pumpUntilFound(tester, find.text('Case details'));
    auth.router.pop();
    await tester.tap(primaryButton('Refer to MOPH coordination'));
    await pumpUntilFound(
      tester,
      find.text('MOPH coordination referral already submitted'),
    );
    auth.router.go(Routes.barangaySubmittedReferrals);
    await pumpUntilFound(tester, find.text('Submitted referrals'));
    await tester.tap(find.byType(ListTile).first);
    await pumpUntilFound(tester, find.text('Submitted referral'));
    await tester.tap(find.widgetWithText(FilledButton, 'Submit update'));
    await auth.signOutCurrentUser();

    await auth.signInAsMoph(credentials.mophPassword);
    await tester.tap(find.byType(ListTile).first);
    await pumpUntilFound(tester, find.text('Coordination referral'));
    await tester.tap(primaryButton('Mark coordination complete'));
    await auth.signOutCurrentUser();

    // Teen — coordination progress without unauthorized identifying labels.
    await auth.signInAsTeenager(credentials.teenPassword);
    auth.router.go(Routes.teenAssistanceList);
    await tester.tap(find.textContaining(runToken).first);
    await pumpUntilFound(tester, find.textContaining('Progress:'));
    expect(find.textContaining('legal_name'), findsNothing);
    await auth.signOutCurrentUser();
  });

  testWidgets('legal gate off blocks teen approve UI snackbar', (tester) async {
    expect(gateOn, isFalse);

    await prepareEmulatorIntegrationSession(tester);
    final auth = harnessFor(tester);

    await auth.signInAsBarangay(credentials.barangayPassword);
    auth.router.go(Routes.barangayIncomingRequests);
    await pumpUntilFound(tester, find.text('Incoming requests'));
    final card = find.byType(ListTile).first;
    await tester.tap(card);
    await pumpUntilFound(tester, find.text('MOPH disclosure authorization'));
    if (find.text('Acknowledged').evaluate().isEmpty) {
      await tester.tap(primaryButton('Acknowledge receipt'));
      await pumpUntilFound(tester, find.text('Acknowledged'));
    }
    if (find.textContaining('Latest authorization status').evaluate().isEmpty) {
      await tester.tap(primaryButton('Request authorization'));
      await pumpUntilFound(
        tester,
        find.textContaining('Latest authorization status'),
      );
    }
    await auth.signOutCurrentUser();

    await auth.signInAsTeenager(credentials.teenPassword);
    auth.router.go(Routes.teenAssistanceList);
    await tester.tap(find.byType(ListTile).first);
    if (find.text('Hospital disclosure authorization').evaluate().isNotEmpty) {
      await tester.tap(primaryButton('Approve'));
      await pumpUntilFound(
        tester,
        find.textContaining('not legally activated on this build'),
      );
    }
    await auth.signOutCurrentUser();
  });
}
