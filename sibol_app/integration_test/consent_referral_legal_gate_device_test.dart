import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:sibol_app/core/constants/route_constants.dart';
import 'package:sibol_app/features/disclosure/domain/disclosure_constants.dart';
import 'support/emulator_auth_harness.dart';
import 'support/emulator_test_bootstrap.dart';
import 'support/emulator_test_accounts.dart';
import 'support/wait_for_widget.dart';

/// Isolated synthetic positive path — requires Functions emulator
/// `SIBOL_DISCLOSURE_LEGAL_GATE=true` and Flutter `--dart-define=SIBOL_DISCLOSURE_LEGAL_GATE=true`.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  if (!DisclosureLegalPolicy.identifyingDisclosureActivated) {
    testWidgets('skipped — legal gate not enabled on build', (_) async {});
    return;
  }

  final credentials = EmulatorTestCredentials.fromEnvironment();

  testWidgets('teen can approve authorization when legal gate enabled', (tester) async {
    await prepareEmulatorIntegrationSession(tester);
    final auth = harnessFor(tester);

    await auth.signInAsTeenager(credentials.teenPassword);
    auth.router.go(Routes.teenAssistanceList);
    await pumpUntilFound(tester, find.text('My requests'));
    if (find.byType(ListTile).evaluate().isEmpty) {
      fail('No assistance requests — run consent workflow seed or prior test data.');
    }
    await tester.tap(find.byType(ListTile).first);
    await pumpUntilFound(tester, find.text('Hospital disclosure authorization'));
    await tester.tap(primaryButton('Approve'));
    await pumpUntilFound(
      tester,
      find.textContaining('Decision recorded: approved'),
    );
    await auth.signOutCurrentUser();
  });
}
