import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:sibol_app/config/emulator_config.dart';
import 'package:sibol_app/config/emulator_firebase_options.dart';
import 'package:sibol_app/config/emulator_hosts.dart';
import 'package:sibol_app/config/firebase_isolation.dart';
import 'package:sibol_app/main_common.dart';

/// Gate F — iOS Debug runtime Firebase isolation (emulator-only).
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Gate F positive: Debug uses demo-sibol-emulator and local emulators', (
    tester,
  ) async {
    FirebaseIsolation.assertIntegrationTestPreflight();
    await initializeSibolFirebase();

    final options = Firebase.app().options;
    expect(options.projectId, EmulatorFirebaseOptions.projectId);
    expect(options.projectId, isNot(FirebaseIsolation.productionProjectId));

    expect(EmulatorHosts.firebase, 'localhost');
    expect(EmulatorConfig.authPort, 9099);
    expect(EmulatorConfig.firestorePort, 8195);
    expect(EmulatorConfig.functionsPort, 5001);

    final email =
        'gate-f-ios-${DateTime.now().millisecondsSinceEpoch}@sibol-emulator.test';
    final password = 'gate-f-password';
    UserCredential credential;
    try {
      credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException {
      credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    }
    expect(credential.user, isNotNull);

    // Firestore emulator round-trip (local host routing).
    final docRef = FirebaseFirestore.instance
        .collection('_isolation_gate_f')
        .doc('ios-${DateTime.now().millisecondsSinceEpoch}');
    await docRef.set({'probe': true, 'platform': defaultTargetPlatform.name});
    final snap = await docRef.get();
    expect(snap.data()?['probe'], isTrue);

    // Functions instance uses emulator configuration (no production URL assertion in SDK).
    expect(FirebaseFunctions.instance, isNotNull);

    await FirebaseAuth.instance.signOut();
  });

  testWidgets('Gate F negative: production project id rejected before network', (
    tester,
  ) async {
    expect(
      () => FirebaseIsolation.assertProjectAfterInit('sibol-286d0'),
      throwsStateError,
    );
    expect(
      () => FirebaseIsolation.enforceConfiguration(
        useEmulators: false,
        environment: 'development',
        releaseMode: false,
        useEmulatorsDefine: 'false',
        authorizedProductionRelease: false,
      ),
      throwsStateError,
    );
  });
}
