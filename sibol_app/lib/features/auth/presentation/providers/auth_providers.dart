import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sibol_app/core/errors/app_exception.dart';
import 'package:sibol_app/core/providers/firebase_providers.dart';
import 'package:sibol_app/features/auth/domain/entities/auth_user.dart';
import 'package:sibol_app/features/auth/domain/entities/user_profile.dart';
import 'package:sibol_app/features/teen_registration/presentation/providers/teen_registration_intent_providers.dart';

final authStateChangesProvider = StreamProvider<AuthUser?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});

final userProfileProvider = StreamProvider<UserProfile?>((ref) {
  final authAsync = ref.watch(authStateChangesProvider);
  return authAsync.when(
    loading: () => const Stream<UserProfile?>.empty(),
    error: (error, stackTrace) =>
        Stream<UserProfile?>.error(error, stackTrace),
    data: (auth) {
      if (auth == null) {
        return Stream.value(null);
      }
      return ref.watch(userProfileRepositoryProvider).watchProfile(auth.uid);
    },
  );
});

/// Re-subscribes auth and profile streams after a startup failure.
void retryStartup(WidgetRef ref) {
  ref.invalidate(authStateChangesProvider);
  ref.invalidate(userProfileProvider);
}

class AuthController extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  /// Clears a prior sign-in failure (e.g. when reopening [LoginScreen]).
  void clearSignInError() {
    if (!state.isLoading && state.hasError) {
      state = const AsyncData(null);
    }
  }

  Future<void> signIn(String email, String password) async {
    state = const AsyncLoading();
    try {
      await ref.read(authRepositoryProvider).signInWithEmail(
            email: email,
            password: password,
          );
      state = const AsyncData(null);
    } on AppException catch (e, st) {
      state = AsyncError(e.toFailure(), st);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> registerWithEmail(String email, String password) async {
    state = const AsyncLoading();
    try {
      await ref.read(authRepositoryProvider).registerWithEmail(
            email: email,
            password: password,
          );
      state = const AsyncData(null);
    } on AppException catch (e, st) {
      state = AsyncError(e.toFailure(), st);
      rethrow;
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  Future<void> sendEmailVerification() async {
    await ref.read(authRepositoryProvider).sendEmailVerification();
  }

  Future<AuthUser> reloadCurrentUser() async {
    return ref.read(authRepositoryProvider).reloadCurrentUser();
  }

  Future<void> sendPasswordResetEmail(String email) async {
    state = const AsyncLoading();
    try {
      await ref.read(authRepositoryProvider).sendPasswordResetEmail(email);
      state = const AsyncData(null);
    } on AppException catch (e, st) {
      state = AsyncError(e.toFailure(), st);
      rethrow;
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  Future<void> signOut() async {
    state = const AsyncLoading();
    try {
      await ref.read(teenRegistrationIntentProvider.notifier).clear();
      await ref.read(authRepositoryProvider).signOut();
      state = const AsyncData(null);
    } on AppException catch (e, st) {
      state = AsyncError(e.toFailure(), st);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}

final authControllerProvider =
    NotifierProvider<AuthController, AsyncValue<void>>(AuthController.new);
