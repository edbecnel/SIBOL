import 'package:flutter_test/flutter_test.dart';
import 'package:sibol_app/features/teen_registration/domain/teen_registration_validation.dart';

void main() {
  const validDob = '2010-06-15';

  group('validateIdentity', () {
    test('accepts email contact only', () {
      expect(
        TeenRegistrationValidation.validateIdentity(
          fullName: 'Demo Teen',
          dateOfBirth: validDob,
          contactEmail: 'teen@sibol.local',
          contactPhone: '',
          barangaySelected: true,
        ),
        isNull,
      );
    });

    test('accepts phone contact only', () {
      expect(
        TeenRegistrationValidation.validateIdentity(
          fullName: 'Demo Teen',
          dateOfBirth: validDob,
          contactEmail: '',
          contactPhone: '+639171234567',
          barangaySelected: true,
        ),
        isNull,
      );
    });

    test('accepts both contact methods', () {
      expect(
        TeenRegistrationValidation.validateIdentity(
          fullName: 'Demo Teen',
          dateOfBirth: validDob,
          contactEmail: 'teen@sibol.local',
          contactPhone: '+639171234567',
          barangaySelected: true,
        ),
        isNull,
      );
    });

    test('rejects when both contacts absent', () {
      expect(
        TeenRegistrationValidation.validateIdentity(
          fullName: 'Demo Teen',
          dateOfBirth: validDob,
          contactEmail: '',
          contactPhone: '',
          barangaySelected: true,
        ),
        isNotNull,
      );
    });

    test('rejects missing full name', () {
      expect(
        TeenRegistrationValidation.validateIdentity(
          fullName: ' ',
          dateOfBirth: validDob,
          contactEmail: 'teen@sibol.local',
          contactPhone: '',
          barangaySelected: true,
        ),
        isNotNull,
      );
    });

    test('rejects invalid DOB', () {
      expect(
        TeenRegistrationValidation.validateIdentity(
          fullName: 'Demo Teen',
          dateOfBirth: 'not-a-date',
          contactEmail: 'teen@sibol.local',
          contactPhone: '',
          barangaySelected: true,
        ),
        isNotNull,
      );
    });

    test('rejects missing barangay selection', () {
      expect(
        TeenRegistrationValidation.validateIdentity(
          fullName: 'Demo Teen',
          dateOfBirth: validDob,
          contactEmail: 'teen@sibol.local',
          contactPhone: '',
          barangaySelected: false,
        ),
        isNotNull,
      );
    });

    test('whitespace email with valid phone uses phone path', () {
      expect(
        TeenRegistrationValidation.validateIdentity(
          fullName: 'Demo Teen',
          dateOfBirth: validDob,
          contactEmail: '   ',
          contactPhone: '+639171234567',
          barangaySelected: true,
        ),
        isNull,
      );
    });
  });

  test('computedAge returns adolescent age from DOB', () {
    final age = TeenRegistrationValidation.computedAge(validDob);
    expect(age, isNotNull);
    expect(age!, greaterThanOrEqualTo(10));
    expect(age!, lessThanOrEqualTo(19));
  });

  test('validateBeforeAccountCreation requires consent and passwords', () {
    expect(
      TeenRegistrationValidation.validateBeforeAccountCreation(
        fullName: 'Demo Teen',
        dateOfBirth: validDob,
        contactEmail: 'teen@sibol.local',
        contactPhone: '',
        barangaySelected: true,
        signInEmail: 'signin@sibol.local',
        password: '12345678',
        confirmPassword: '12345678',
        privacyConsent: false,
      ),
      isNotNull,
    );
  });

  test('validateBeforeAccountCreation passes complete payload', () {
    expect(
      TeenRegistrationValidation.validateBeforeAccountCreation(
        fullName: 'Demo Teen',
        dateOfBirth: validDob,
        contactEmail: 'contact@sibol.local',
        contactPhone: '',
        barangaySelected: true,
        signInEmail: 'signin@sibol.local',
        password: '12345678',
        confirmPassword: '12345678',
        privacyConsent: true,
      ),
      isNull,
    );
  });
}
