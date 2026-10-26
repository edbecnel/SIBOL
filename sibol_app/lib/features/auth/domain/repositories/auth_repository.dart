import 'package:sibol_app/features/auth/domain/entities/auth_user.dart';

abstract class AuthRepository {
  Stream<AuthUser?> get authStateChanges;

  AuthUser? get currentUser;

  Future<AuthUser> signInWithEmail({
    required String email,
    required String password,
  });

  Future<void> signOut();

  Future<AuthUser> registerWithEmail({
    required String email,
    required String password,
  });

  Future<void> sendEmailVerification();

  Future<AuthUser> reloadCurrentUser();

  Future<void> sendPasswordResetEmail(String email);

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  });

  Future<void> acknowledgeMandatoryPasswordChange();
}
