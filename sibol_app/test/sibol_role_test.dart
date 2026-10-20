import 'package:flutter_test/flutter_test.dart';
import 'package:sibol_app/core/permissions/sibol_role.dart';

void main() {
  test('parses firestore role values', () {
    expect(SibolRole.fromFirestore('teen'), SibolRole.teen);
    expect(SibolRole.fromFirestore('barangay'), SibolRole.barangay);
    expect(SibolRole.fromFirestore('moph'), SibolRole.moph);
    expect(SibolRole.fromFirestore('admin'), isNull);
  });
}
