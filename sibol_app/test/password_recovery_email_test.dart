import 'package:flutter_test/flutter_test.dart';
import 'package:sibol_app/features/auth/domain/password_recovery_email.dart';

void main() {
  group('PasswordRecoveryEmail', () {
    test('rejects empty email', () {
      expect(PasswordRecoveryEmail.validateForPasswordReset(''), isNotNull);
    });

    test('rejects invalid format', () {
      expect(PasswordRecoveryEmail.validateForPasswordReset('not-an-email'), isNotNull);
    });

    test('rejects .local demonstration addresses', () {
      expect(
        PasswordRecoveryEmail.validateForPasswordReset('teen.demo@sibol.local'),
        isNotNull,
      );
      expect(
        PasswordRecoveryEmail.validateForPasswordReset('user@demo.local'),
        isNotNull,
      );
    });

    test('accepts real email addresses', () {
      expect(
        PasswordRecoveryEmail.validateForPasswordReset('user@gmail.com'),
        isNull,
      );
    });
  });
}
