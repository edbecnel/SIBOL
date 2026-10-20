import 'package:sibol_app/features/auth/domain/entities/auth_user.dart';
import 'package:sibol_app/features/auth/domain/entities/user_profile.dart';
import 'package:sibol_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:sibol_app/features/auth/domain/repositories/user_profile_repository.dart';

class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository(this._authStateChanges);

  final Stream<AuthUser?> _authStateChanges;

  @override
  Stream<AuthUser?> get authStateChanges => _authStateChanges;

  @override
  AuthUser? get currentUser => null;

  @override
  Future<AuthUser> signInWithEmail({
    required String email,
    required String password,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> signOut() => throw UnimplementedError();
}

class FakeUserProfileRepository implements UserProfileRepository {
  FakeUserProfileRepository(this._profiles);

  final Map<String, Stream<UserProfile?>> _profiles;

  @override
  Stream<UserProfile?> watchProfile(String uid) {
    return _profiles[uid] ?? Stream<UserProfile?>.value(null);
  }

  @override
  Future<UserProfile?> fetchProfile(String uid) async => null;
}

/// Auth repo whose [authStateChanges] stream changes after each invalidation.
class RetryableAuthRepository implements AuthRepository {
  RetryableAuthRepository(this._streamForAttempt);

  final Stream<AuthUser?> Function(int attempt) _streamForAttempt;

  int _attempt = 0;

  int get subscribeCount => _attempt;

  @override
  Stream<AuthUser?> get authStateChanges => _streamForAttempt(++_attempt);

  @override
  AuthUser? get currentUser => null;

  @override
  Future<AuthUser> signInWithEmail({
    required String email,
    required String password,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> signOut() => throw UnimplementedError();
}
