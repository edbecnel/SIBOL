import 'package:sibol_app/core/errors/failure.dart';

class AppException implements Exception {
  const AppException({required this.message, this.code});

  final String message;
  final String? code;

  @override
  String toString() => message;

  Failure toFailure() => UnknownFailure(message: message);
}

class AuthException extends AppException {
  const AuthException({required super.message, super.code});

  @override
  Failure toFailure() => AuthFailure(
        code: code ?? 'unknown',
        message: _mapCode(code) ?? message,
      );

  static String? _mapCode(String? code) {
    switch (code) {
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Invalid email or password.';
      case 'user-disabled':
        return 'This demonstration account is disabled.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait and try again.';
      case 'network-request-failed':
        return 'Network error. Check your connection or ensure the Firebase emulator is running.';
      case 'email-already-in-use':
        return 'This email is already registered. Sign in or use a different email.';
      case 'invalid-email':
        return 'Enter a valid email address.';
      case 'weak-password':
        return 'Password is too weak. Use at least 6 characters.';
      case 'operation-not-allowed':
        return 'This sign-in method is not enabled for this app.';
      case 'internal-error':
        return 'Authentication service error. If you use local emulators, ensure they are running and retry.';
      default:
        return null;
    }
  }
}
