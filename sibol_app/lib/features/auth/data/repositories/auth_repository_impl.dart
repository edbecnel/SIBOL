import 'dart:developer' as developer;

import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sibol_app/core/errors/app_exception.dart';
import 'package:sibol_app/features/auth/domain/entities/auth_user.dart';
import 'package:sibol_app/features/auth/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._firebaseAuth, this._functions);

  final FirebaseAuth _firebaseAuth;
  final FirebaseFunctions _functions;

  @override
  Stream<AuthUser?> get authStateChanges {
    return _firebaseAuth.authStateChanges().map(_mapUser);
  }

  @override
  AuthUser? get currentUser => _mapUser(_firebaseAuth.currentUser);

  @override
  Future<AuthUser> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = credential.user;
      if (user == null) {
        throw const AuthException(message: 'Sign in failed');
      }
      return _mapUser(user)!;
    } on FirebaseAuthException catch (e) {
      developer.log('signInWithEmail failed', name: 'AuthRepository', error: e);
      throw AuthException(message: e.message ?? 'Sign in failed', code: e.code);
    } catch (e, st) {
      developer.log('signInWithEmail unexpected', name: 'AuthRepository', error: e, stackTrace: st);
      throw const AuthException(
        message: 'Sign in failed. Check your connection or emulator.',
        code: 'network-request-failed',
      );
    }
  }

  @override
  Future<void> signOut() => _firebaseAuth.signOut();

  AuthUser? _mapUser(User? user) {
    if (user == null) return null;
    return AuthUser(
      uid: user.uid,
      email: user.email ?? '',
      displayName: user.displayName,
      emailVerified: user.emailVerified,
    );
  }

  @override
  Future<AuthUser> registerWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = credential.user;
      if (user == null) {
        throw const AuthException(message: 'Registration failed');
      }
      return _mapUser(user)!;
    } on FirebaseAuthException catch (e) {
      developer.log('registerWithEmail failed', name: 'AuthRepository', error: e);
      throw AuthException(message: e.message ?? 'Registration failed', code: e.code);
    } catch (e, st) {
      developer.log('registerWithEmail unexpected', name: 'AuthRepository', error: e, stackTrace: st);
      throw const AuthException(
        message: 'Registration failed. Check your connection or emulator.',
        code: 'network-request-failed',
      );
    }
  }

  @override
  Future<void> sendEmailVerification() async {
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      throw const AuthException(message: 'Not signed in');
    }
    try {
      await user.sendEmailVerification();
    } on FirebaseAuthException catch (e) {
      throw AuthException(message: e.message ?? 'Could not send email', code: e.code);
    }
  }

  @override
  Future<AuthUser> reloadCurrentUser() async {
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      throw const AuthException(message: 'Not signed in');
    }
    await user.reload();
    return _mapUser(_firebaseAuth.currentUser)!;
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw AuthException(message: e.message ?? 'Password reset failed', code: e.code);
    }
  }

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final user = _firebaseAuth.currentUser;
    if (user == null || user.email == null || user.email!.isEmpty) {
      throw const AuthException(message: 'Not signed in');
    }
    try {
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(newPassword);
    } on FirebaseAuthException catch (e) {
      throw AuthException(
        message: e.message ?? 'Could not update password',
        code: e.code,
      );
    }
  }

  @override
  Future<void> acknowledgeMandatoryPasswordChange() async {
    try {
      await _functions
          .httpsCallable('regAcknowledgeMandatoryPasswordChange')
          .call();
    } on FirebaseFunctionsException catch (e) {
      throw AuthException(
        message: e.message ?? 'Could not confirm password change',
        code: e.code,
      );
    }
  }
}
