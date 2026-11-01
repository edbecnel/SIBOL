import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sibol_app/config/firebase_isolation.dart';

void main() {
  group('FirebaseIsolation.enforceConfiguration', () {
    test('rejects USE_FIREBASE_EMULATORS=false outside release', () {
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

    test('rejects ENVIRONMENT=production in debug', () {
      expect(
        () => FirebaseIsolation.enforceConfiguration(
          useEmulators: true,
          environment: 'production',
          releaseMode: false,
          useEmulatorsDefine: '',
          authorizedProductionRelease: false,
        ),
        throwsStateError,
      );
    });

    test('rejects production project id constant misuse', () {
      expect(FirebaseIsolation.productionProjectId, 'sibol-286d0');
      expect(FirebaseIsolation.emulatorProjectId, isNot('sibol-286d0'));
    });

    test('assertProjectAfterInit rejects production in non-release paths', () {
      if (kReleaseMode) return;
      expect(
        () => FirebaseIsolation.assertProjectAfterInit('sibol-286d0'),
        throwsStateError,
      );
    });

    test('assertProjectAfterInit accepts demo project in debug', () {
      if (kReleaseMode) return;
      expect(
        () => FirebaseIsolation.assertProjectAfterInit('demo-sibol-emulator'),
        returnsNormally,
      );
    });
  });
}
