import 'package:flutter/foundation.dart';
import 'package:sibol_app/config/emulator_config.dart';
import 'package:sibol_app/config/emulator_firebase_options.dart';
import 'package:sibol_app/config/emulator_hosts.dart';
import 'package:sibol_app/config/env_config.dart';
import 'package:sibol_app/config/firebase_options.dart';

/// Fail-closed production isolation for SIBOL Firebase (SIBOL-FIREBASE-ISOLATION-001).
abstract final class FirebaseIsolation {
  static const String productionProjectId = 'sibol-286d0';
  static const String emulatorProjectId = EmulatorFirebaseOptions.projectId;

  /// Release builds may use live Firebase when emulators are off.
  /// Debug, profile, and test processes may not use this path.
  static bool get authorizedProductionReleaseClient =>
      kReleaseMode &&
      const bool.fromEnvironment(
        'SIBOL_AUTHORIZED_PRODUCTION_RELEASE',
        defaultValue: true,
      );

  /// Throws [StateError] with an `ISOLATION:` prefix before any Firebase init.
  static void enforceBeforeFirebaseInit() {
    enforceConfiguration(
      useEmulators: EnvConfig.useEmulators,
      environment: EnvConfig.environment,
      releaseMode: kReleaseMode,
      useEmulatorsDefine: const String.fromEnvironment('USE_FIREBASE_EMULATORS'),
      authorizedProductionRelease: authorizedProductionReleaseClient,
    );
  }

  @visibleForTesting
  static void enforceConfiguration({
    required bool useEmulators,
    required String environment,
    required bool releaseMode,
    required String useEmulatorsDefine,
    required bool authorizedProductionRelease,
  }) {
    if (authorizedProductionRelease && !useEmulators) {
      return;
    }

    if (!useEmulators) {
      throw StateError(
        'ISOLATION: USE_FIREBASE_EMULATORS=false is forbidden outside an '
        'authorized production release build. Start canonical emulators and '
        'use --dart-define=USE_FIREBASE_EMULATORS=true for local work.',
      );
    }

    if (environment == 'production' && !releaseMode) {
      throw StateError(
        'ISOLATION: ENVIRONMENT=production is forbidden in debug, profile, '
        'or test builds. Use development/staging with emulators.',
      );
    }

    if (useEmulatorsDefine == 'false') {
      throw StateError(
        'ISOLATION: explicit USE_FIREBASE_EMULATORS=false is forbidden in '
        'non-release builds.',
      );
    }

    _assertEmulatorHostConfiguration();
  }

  static void _assertEmulatorHostConfiguration() {
    final host = EmulatorHosts.firebase;
    if (host.isEmpty) {
      throw StateError(
        'ISOLATION: emulator host is empty; cannot route Auth/Firestore/Functions.',
      );
    }
    if (EmulatorConfig.authPort <= 0 ||
        EmulatorConfig.firestorePort <= 0 ||
        EmulatorConfig.functionsPort <= 0) {
      throw StateError(
        'ISOLATION: canonical emulator ports must be configured (9099/8195/5001).',
      );
    }
  }

  static void assertProjectAfterInit(String projectId) {
    if (authorizedProductionReleaseClient && !EnvConfig.useEmulators) {
      if (projectId != DefaultFirebaseOptions.currentPlatform.projectId) {
        throw StateError(
          'ISOLATION: authorized production release expected '
          '${DefaultFirebaseOptions.currentPlatform.projectId}; found $projectId.',
        );
      }
      if (projectId == productionProjectId && kDebugMode) {
        throw StateError(
          'ISOLATION: production project $productionProjectId must not load in debug mode.',
        );
      }
      return;
    }

    if (projectId == productionProjectId) {
      throw StateError(
        'ISOLATION: production project $productionProjectId is forbidden in '
        'debug/test/emulator workflows.',
      );
    }
    if (projectId != emulatorProjectId) {
      throw StateError(
        'ISOLATION: emulator workflows require $emulatorProjectId; found $projectId.',
      );
    }
  }

  /// Integration/device tests call before Firebase I/O.
  static void assertIntegrationTestPreflight() {
    enforceBeforeFirebaseInit();
    if (!EnvConfig.useEmulators) {
      throw StateError('ISOLATION: integration tests require USE_FIREBASE_EMULATORS=true.');
    }
  }
}
