import 'package:flutter_test/flutter_test.dart';
import 'package:sibol_app/config/env_config.dart';

void main() {
  test('development defaults to Firebase emulators when define unset', () {
    expect(EnvConfig.environment, 'development');
    expect(EnvConfig.useEmulators, isTrue);
  });
}
