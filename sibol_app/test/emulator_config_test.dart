import 'package:flutter_test/flutter_test.dart';
import 'package:sibol_app/config/emulator_config.dart';
import 'package:sibol_app/config/emulator_firebase_options.dart';

void main() {
  test('demonstration emulator ports match firebase.json', () {
    expect(EmulatorConfig.authPort, 9099);
    expect(EmulatorConfig.firestorePort, 8195);
    expect(EmulatorConfig.functionsPort, 5001);
  });

  test('emulator Firebase options stay on demo project (not sibol-286d0)', () {
    final options = EmulatorFirebaseOptions.currentPlatform;
    expect(options.projectId, 'demo-sibol-emulator');
    expect(options.appId, isNot(contains('1057794781295')));
    expect(options.projectId, isNot(contains('286d0')));
  });
}
