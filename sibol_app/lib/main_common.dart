import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sibol_app/app.dart';
import 'package:sibol_app/config/emulator_config.dart';
import 'package:sibol_app/config/emulator_hosts.dart';
import 'package:sibol_app/config/emulator_firebase_options.dart';
import 'package:sibol_app/config/env_config.dart';
import 'package:sibol_app/config/firebase_options.dart';

bool _emulatorEndpointsConfigured = false;
bool _sibolApplicationStarted = false;

/// Firebase + emulator wiring (safe to call once per process).
Future<void> initializeSibolFirebase() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  if (kIsWeb) {
    throw UnsupportedError('Flutter Web is not authorized for SIBOL.');
  }

  if (EnvConfig.useEmulators && Firebase.apps.isNotEmpty) {
    final existing = Firebase.app();
    if (existing.options.projectId != EmulatorFirebaseOptions.projectId) {
      await existing.delete();
      _emulatorEndpointsConfigured = false;
    }
  }

  if (Firebase.apps.isEmpty) {
    try {
      await Firebase.initializeApp(
        options: EnvConfig.useEmulators
            ? EmulatorFirebaseOptions.currentPlatform
            : DefaultFirebaseOptions.currentPlatform,
      );
    } on FirebaseException catch (e) {
      if (e.code != 'duplicate-app') rethrow;
      if (EnvConfig.useEmulators) {
        final existing = Firebase.app();
        if (existing.options.projectId != EmulatorFirebaseOptions.projectId) {
          await existing.delete();
          _emulatorEndpointsConfigured = false;
          await Firebase.initializeApp(
            options: EmulatorFirebaseOptions.currentPlatform,
          );
        }
      }
    }
  }

  if (Firebase.apps.isEmpty) {
    throw StateError('Firebase did not initialize.');
  }

  if (EnvConfig.useEmulators) {
    final projectId = Firebase.app().options.projectId;
    if (projectId != EmulatorFirebaseOptions.projectId) {
      throw StateError(
        'Emulator run requires project ${EmulatorFirebaseOptions.projectId}; '
        'found $projectId.',
      );
    }
  }

  if (EnvConfig.useEmulators && !_emulatorEndpointsConfigured) {
    final host = EmulatorHosts.firebase;
    await FirebaseAuth.instance.useAuthEmulator(host, EmulatorConfig.authPort);
    FirebaseFirestore.instance.useFirestoreEmulator(
      host,
      EmulatorConfig.firestorePort,
    );
    FirebaseFunctions.instance.useFunctionsEmulator(
      host,
      EmulatorConfig.functionsPort,
    );
    _emulatorEndpointsConfigured = true;
  }

  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
  );
}

void runSibolApplication() {
  if (_sibolApplicationStarted) {
    return;
  }
  runApp(const ProviderScope(child: SibolApp()));
  _sibolApplicationStarted = true;
}

Future<void> mainCommon() async {
  await initializeSibolFirebase();
  runSibolApplication();
}
