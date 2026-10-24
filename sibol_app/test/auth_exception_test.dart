import 'package:flutter_test/flutter_test.dart';
import 'package:sibol_app/core/errors/app_exception.dart';
import 'package:sibol_app/core/errors/user_error_message.dart';

void main() {
  group('AuthException', () {
    test('toString returns message not type name', () {
      const ex = AuthException(message: 'Registration failed', code: 'unknown');
      expect(ex.toString(), 'Registration failed');
      expect(ex.toString(), isNot(contains('Instance of')));
    });

    test('maps email-already-in-use', () {
      const ex = AuthException(message: 'raw', code: 'email-already-in-use');
      expect(ex.toFailure().message, contains('already registered'));
    });

    test('maps weak-password', () {
      const ex = AuthException(message: 'raw', code: 'weak-password');
      expect(ex.toFailure().message, contains('too weak'));
    });

    test('maps invalid-email', () {
      const ex = AuthException(message: 'raw', code: 'invalid-email');
      expect(ex.toFailure().message, contains('valid email'));
    });

    test('userErrorMessage uses mapped auth failure', () {
      const ex = AuthException(message: 'raw', code: 'email-already-in-use');
      expect(userErrorMessage(ex), contains('already registered'));
    });
  });
}
