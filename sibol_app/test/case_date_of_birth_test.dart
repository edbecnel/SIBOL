import 'package:flutter_test/flutter_test.dart';
import 'package:sibol_app/features/cases/domain/case_date_of_birth.dart';

void main() {
  test('parses valid date of birth', () {
    final dob = CaseDateOfBirth.parse('2008-05-12');
    expect(dob, isNotNull);
    expect(dob!.toStorageString(), '2008-05-12');
  });

  test('rejects future birthdates', () {
    final error = CaseDateOfBirth.validateForAdolescentCase(
      '2099-01-01',
      referenceDate: DateTime(2026, 10, 26),
    );
    expect(error, isNotNull);
  });

  test('computes historical age on event date', () {
    final dob = CaseDateOfBirth.parse('2008-05-12')!;
    expect(
      CaseDateOfBirth.ageOnDate(dob, DateTime(2020, 5, 11)),
      11,
    );
    expect(
      CaseDateOfBirth.ageOnDate(dob, DateTime(2020, 5, 12)),
      12,
    );
  });
}
