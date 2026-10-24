import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final mainManifest = File('android/app/src/main/AndroidManifest.xml');
  final debugManifest = File('android/app/src/debug/AndroidManifest.xml');
  final debugNsc = File('android/app/src/debug/res/xml/network_security_config.xml');
  final profileNsc = File('android/app/src/profile/res/xml/network_security_config.xml');

  test('release main manifest does not enable cleartext or NSC', () {
    final text = mainManifest.readAsStringSync();
    expect(text, isNot(contains('usesCleartextTraffic')));
    expect(text, isNot(contains('networkSecurityConfig')));
  });

  test('debug manifest references emulator network security config', () {
    final text = debugManifest.readAsStringSync();
    expect(text, contains('network_security_config'));
  });

  test('debug NSC permits cleartext only to 10.0.2.2', () {
    final text = debugNsc.readAsStringSync();
    expect(text, contains('cleartextTrafficPermitted="true"'));
    expect(text, contains('10.0.2.2'));
    expect(text.contains('<base-config'), isFalse);
  });

  test('profile NSC matches debug emulator host allowance', () {
    final text = profileNsc.readAsStringSync();
    expect(text, contains('10.0.2.2'));
  });
}
