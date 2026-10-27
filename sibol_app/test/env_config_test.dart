import 'package:flutter_test/flutter_test.dart';
import 'package:sibol_app/config/env_config.dart';

void main() {
  test('development defaults to Firebase emulators when define unset', () {
    expect(EnvConfig.environment, 'development');
    expect(EnvConfig.useEmulators, isTrue);
  });

  group('resolveUseFirebaseEmulators', () {
    test('release build never defaults to emulators', () {
      expect(
        resolveUseFirebaseEmulators(
          useFirebaseEmulatorsDefine: '',
          environment: 'development',
          releaseMode: true,
        ),
        isFalse,
      );
    });

    test('debug development defaults to emulators when define unset', () {
      expect(
        resolveUseFirebaseEmulators(
          useFirebaseEmulatorsDefine: '',
          environment: 'development',
          releaseMode: false,
        ),
        isTrue,
      );
    });

    test('production environment disables emulators when define unset', () {
      expect(
        resolveUseFirebaseEmulators(
          useFirebaseEmulatorsDefine: '',
          environment: 'production',
          releaseMode: false,
        ),
        isFalse,
      );
    });

    test('explicit false disables emulators', () {
      expect(
        resolveUseFirebaseEmulators(
          useFirebaseEmulatorsDefine: 'false',
          environment: 'development',
          releaseMode: false,
        ),
        isFalse,
      );
    });
  });
}
