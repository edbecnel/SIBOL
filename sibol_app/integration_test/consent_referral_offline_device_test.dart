import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:sibol_app/core/constants/route_constants.dart';
import 'package:sibol_app/features/teenager/domain/assistance_request_category.dart';
import 'support/emulator_auth_harness.dart';
import 'support/emulator_test_bootstrap.dart';
import 'support/emulator_test_accounts.dart';
import 'support/wait_for_widget.dart';

/// Offline structured referral queue — run with airplane mode enabled by
/// `run-consent-referral-device-test.sh` (`SIBOL_RUN_CONSENT_OFFLINE_DEVICE_TEST=1`).
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  final credentials = EmulatorTestCredentials.fromEnvironment();

  testWidgets('structured referral queues locally without profile fields in UI', (
    tester,
  ) async {
    final runToken = 'offline-ref-${DateTime.now().toUtc().millisecondsSinceEpoch}';

    await prepareEmulatorIntegrationSession(tester);
    final auth = harnessFor(tester);

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
      'Offline referral queue test $runToken',
    );
    await tester.tap(primaryButton('Submit request'));
    await pumpUntilFound(tester, find.textContaining(runToken));
    await auth.signOutCurrentUser();

    await auth.signInAsBarangay(credentials.barangayPassword);
    auth.router.go(Routes.barangayIncomingRequests);
    await pumpUntilFound(tester, find.text('Incoming requests'));
    await tester.tap(find.textContaining(runToken).first);
    await tester.tap(primaryButton('Acknowledge receipt'));
    await pumpUntilFound(tester, find.text('Acknowledged'));
    await tester.tap(primaryButton('Refer to MOPH coordination'));
    await pumpUntilFound(tester, find.text('Structured MOPH referral'));
    await tester.tap(primaryButton('Submit referral'));
    await pumpUntilFound(
      tester,
      find.textContaining('queued locally'),
    );
    expect(find.textContaining('legal_name'), findsNothing);
    await auth.signOutCurrentUser();
  });
}
