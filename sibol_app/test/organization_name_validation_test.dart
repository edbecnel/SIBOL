import 'package:flutter_test/flutter_test.dart';
import 'package:sibol_app/features/admin/domain/organization_name_validation.dart';

void main() {
  test('normalize collapses whitespace', () {
    expect(
      OrganizationNameValidation.normalize('  Demo   Hospital  '),
      'Demo Hospital',
    );
  });

  test('rejects empty hospital name', () {
    expect(OrganizationNameValidation.validateHospitalName('   '), isNotNull);
  });

  test('accepts valid hospital name', () {
    expect(
      OrganizationNameValidation.validateHospitalName('Misamis Oriental General Hospital'),
      isNull,
    );
  });
}
