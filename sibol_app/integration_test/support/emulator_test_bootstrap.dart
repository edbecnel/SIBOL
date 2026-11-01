import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sibol_app/config/emulator_config.dart';
import 'package:sibol_app/config/emulator_firebase_options.dart';
import 'package:sibol_app/config/emulator_hosts.dart';
import 'package:sibol_app/config/env_config.dart';
import 'package:sibol_app/config/firebase_isolation.dart';
import 'package:sibol_app/main_common.dart';

/// Ensures Firebase + UI start once per integration test process.
class EmulatorIntegrationBootstrap {
  EmulatorIntegrationBootstrap._();
  static bool _sessionReady = false;

  static void assertGateAConfiguration() {
    FirebaseIsolation.assertIntegrationTestPreflight();
    expect(EnvConfig.useEmulators, isTrue, reason: 'USE_FIREBASE_EMULATORS must be true.');
    expect(Firebase.apps, isNotEmpty, reason: 'Firebase must be initialized before Gate A.');
    final options = Firebase.app().options;
    expect(options.projectId, EmulatorFirebaseOptions.projectId);
    expect(options.projectId, isNot(contains('286d0')));
    expect(options.appId, isNot(contains('1057794781295')));
    expect(EmulatorConfig.authPort, 9099);
    expect(EmulatorConfig.firestorePort, 8195);
    expect(EmulatorConfig.functionsPort, 5001);
    expect(EmulatorHosts.firebase, '10.0.2.2');
  }

  static Future<void> launchAppOnce(WidgetTester tester) async {
    if (_sessionReady) {
      assertGateAConfiguration();
      return;
    }
    await initializeSibolFirebase();
    assertGateAConfiguration();
    runSibolApplication();
    await tester.pump(const Duration(seconds: 3));
    _sessionReady = true;
  }

  static Future<void> signOut(WidgetTester tester) async {
    await FirebaseAuth.instance.signOut();
    await tester.pump(const Duration(seconds: 1));
  }
}

/// Legacy name used by device acceptance tests.
Future<void> prepareEmulatorIntegrationSession(WidgetTester tester) =>
    EmulatorIntegrationBootstrap.launchAppOnce(tester);
