import 'package:flutter_test/flutter_test.dart';

String? validateTeenRegistrationPasswords({
  required String password,
  required String confirm,
}) {
  if (password.length < 8) return 'Password must be at least 8 characters.';
  if (password != confirm) return 'Passwords do not match.';
  return null;
}

void main() {
  test('password confirmation rejects mismatch', () {
    expect(
      validateTeenRegistrationPasswords(password: '12345678', confirm: '87654321'),
      isNotNull,
    );
  });

  test('password confirmation accepts match', () {
    expect(
      validateTeenRegistrationPasswords(password: '12345678', confirm: '12345678'),
      isNull,
    );
  });
}
