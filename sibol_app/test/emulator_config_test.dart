import 'package:flutter_test/flutter_test.dart';
import 'package:sibol_app/config/emulator_config.dart';

void main() {
  test('demonstration emulator ports match firebase.json', () {
    expect(EmulatorConfig.authPort, 9099);
    expect(EmulatorConfig.firestorePort, 8195);
    expect(EmulatorConfig.functionsPort, 5001);
  });
}
