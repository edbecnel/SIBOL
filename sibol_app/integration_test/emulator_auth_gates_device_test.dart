import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:sibol_app/core/permissions/sibol_role.dart';
import 'support/emulator_auth_harness.dart';
import 'support/emulator_test_accounts.dart';
import 'support/emulator_test_bootstrap.dart';

/// Gates A–D: configuration, then one login each for Teen / Barangay / MOPH.
/// Stops at first failure (single [testWidgets] — no retry loop).
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late EmulatorTestCredentials credentials;

  setUpAll(() {
    credentials = EmulatorTestCredentials.fromEnvironment();
  });

  testWidgets('Gates A–D emulator authentication and role dashboards', (tester) async {
    // Gate A
    await EmulatorIntegrationBootstrap.launchAppOnce(tester);

    final auth = harnessFor(tester);

    // Gate B — teenager (one login)
    await auth.signInAsTeenager(credentials.teenPassword);
    expect(find.text('Teenager dashboard'), findsOneWidget);
    await auth.signOutCurrentUser();

    // Gate C — barangay (one login)
    await auth.signInAsBarangay(credentials.barangayPassword);
    expect(find.text('Barangay dashboard'), findsOneWidget);
    expect(find.text('Teenager dashboard'), findsNothing);
    await auth.signOutCurrentUser();

    // Gate D — MOPH (one login)
    await auth.signInAsMoph(credentials.mophPassword);
    expect(find.text('MOPH dashboard'), findsOneWidget);
    expect(find.text('Barangay dashboard'), findsNothing);
    await auth.signOutCurrentUser();
  });
}
