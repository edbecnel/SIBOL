import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:sibol_app/config/env_config.dart';
import 'package:sibol_app/core/permissions/sibol_role.dart';
import 'support/emulator_auth_harness.dart';
import 'support/emulator_test_bootstrap.dart';
import 'support/emulator_test_accounts.dart';
import 'support/wait_for_widget.dart';

/// Validates automated sign-in, profile provisioning, role home, and role switching.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late EmulatorTestCredentials credentials;

  setUpAll(() {
    credentials = EmulatorTestCredentials.fromEnvironment();
  });

  Future<void> prepareSession(WidgetTester tester) async {
    expect(EnvConfig.useEmulators, isTrue, reason: 'Pass --dart-define=USE_FIREBASE_EMULATORS=true');
    await prepareEmulatorIntegrationSession(tester);
  }

  testWidgets('emulator synthetic accounts reach role dashboards', (tester) async {
    await prepareSession(tester);

    final auth = harnessFor(tester);

    await auth.signInAsTeenager(credentials.teenPassword);
    await auth.signOutCurrentUser();

    await auth.signInAsBarangay(credentials.barangayPassword);
    await auth.signOutCurrentUser();

    await auth.signInAsMoph(credentials.mophPassword);
    await auth.signOutCurrentUser();
  });

  testWidgets('switchRole clears prior session before next role home', (tester) async {
    await prepareSession(tester);

    final auth = harnessFor(tester);

    await auth.signInAsBarangay(credentials.barangayPassword);
    expect(find.text('Barangay dashboard'), findsOneWidget);
    expect(find.text('MOPH dashboard'), findsNothing);

    await auth.switchRole(
      email: EmulatorTestAccounts.mophEmail,
      password: credentials.mophPassword,
      expectedRole: SibolRole.moph,
    );
    await pumpUntilFound(tester, find.text('MOPH dashboard'));
    expect(find.text('Barangay dashboard'), findsNothing);
  });
}
