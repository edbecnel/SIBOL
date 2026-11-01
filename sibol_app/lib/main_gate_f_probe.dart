import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_functions/firebase_functions.dart';
import 'package:flutter/material.dart';
import 'package:sibol_app/config/emulator_config.dart';
import 'package:sibol_app/config/emulator_firebase_options.dart';
import 'package:sibol_app/config/emulator_hosts.dart';
import 'package:sibol_app/main_common.dart';

/// Debug-only probe entry for Gate F iOS runtime verification (not used in release).
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeSibolFirebase();

  final projectId = Firebase.app().options.projectId;
  // ignore: avoid_print
  print('SIBOL_GATE_F_PROJECT_ID=$projectId');
  // ignore: avoid_print
  print('SIBOL_GATE_F_EMULATOR_HOST=${EmulatorHosts.firebase}');
  // ignore: avoid_print
  print(
    'SIBOL_GATE_F_PORTS=auth:${EmulatorConfig.authPort},'
    'firestore:${EmulatorConfig.firestorePort},'
    'functions:${EmulatorConfig.functionsPort}',
  );
  // ignore: avoid_print
  print('SIBOL_GATE_F_FUNCTIONS_INSTANCE=${FirebaseFunctions.instance.app.name}');

  final email =
      'gate-f-probe-${DateTime.now().millisecondsSinceEpoch}@sibol-emulator.test';
  await FirebaseAuth.instance.createUserWithEmailAndPassword(
    email: email,
    password: 'gate-f-probe-password',
  );
  // ignore: avoid_print
  print('SIBOL_GATE_F_AUTH_OK=true');

  try {
    final doc =
        FirebaseFirestore.instance.collection('_gate_f_probe').doc('ios');
    await doc.set({'ok': true, 'projectId': projectId});
    final snap = await doc.get();
    // ignore: avoid_print
    print('SIBOL_GATE_F_FIRESTORE_OK=${snap.data()?['ok']}');
  } on FirebaseException catch (e) {
    if (e.code == 'permission-denied') {
      // Catch-all deny in firestore.rules — confirms local emulator + rules, not production.
      // ignore: avoid_print
      print('SIBOL_GATE_F_FIRESTORE_EMULATOR_OK=rules-denied-local');
    } else {
      rethrow;
    }
  }

  runApp(
    MaterialApp(
      home: Scaffold(
        body: Center(
          child: Text('Gate F OK\n$projectId\n${EmulatorFirebaseOptions.projectId}'),
        ),
      ),
    ),
  );
}
