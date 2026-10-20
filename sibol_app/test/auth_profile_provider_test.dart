import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sibol_app/core/providers/firebase_providers.dart';
import 'package:sibol_app/features/auth/domain/entities/auth_user.dart';
import 'package:sibol_app/features/auth/domain/entities/user_profile.dart';
import 'package:sibol_app/features/auth/presentation/providers/auth_providers.dart';
import 'support/fake_auth_repositories.dart';

Future<AsyncValue<T>> waitUntilSettled<T>(
  ProviderContainer container,
  StreamProvider<T> provider,
) async {
  final completer = Completer<AsyncValue<T>>();
  late final ProviderSubscription<AsyncValue<T>> sub;

  sub = container.listen(
    provider,
    (previous, next) {
      if (!next.isLoading && !completer.isCompleted) {
        completer.complete(next);
      }
    },
    fireImmediately: true,
  );

  final result = await completer.future.timeout(const Duration(seconds: 2));
  sub.close();
  return result;
}

void main() {
  const signedInUser = AuthUser(uid: 'u1', email: 'a@example.com');

  group('userProfileProvider', () {
    test('auth resolves to null → profile resolves to null', () async {
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWith(
            (ref) => FakeAuthRepository(Stream.value(null)),
          ),
        ],
      );
      addTearDown(container.dispose);

      final profile = await waitUntilSettled(
        container,
        userProfileProvider,
      );

      expect(profile.hasError, isFalse);
      expect(profile.value, isNull);
    });

    test('auth error propagates to profile provider', () async {
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWith(
            (ref) => FakeAuthRepository(
              Stream<AuthUser?>.error(Exception('auth failed')),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      final profile = await waitUntilSettled(
        container,
        userProfileProvider,
      );

      expect(profile.hasError, isTrue);
    });

    test('signed-in auth subscribes to profile stream', () async {
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWith(
            (ref) => FakeAuthRepository(Stream.value(signedInUser)),
          ),
          userProfileRepositoryProvider.overrideWith(
            (ref) => FakeUserProfileRepository({
              'u1': Stream.value(null),
            }),
          ),
        ],
      );
      addTearDown(container.dispose);

      final profile = await waitUntilSettled(
        container,
        userProfileProvider,
      );

      expect(profile.hasError, isFalse);
      expect(profile.value, isNull);
    });

    test('profile stream error propagates when signed in', () async {
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWith(
            (ref) => FakeAuthRepository(Stream.value(signedInUser)),
          ),
          userProfileRepositoryProvider.overrideWith(
            (ref) => FakeUserProfileRepository({
              'u1': Stream<UserProfile?>.error(Exception('profile failed')),
            }),
          ),
        ],
      );
      addTearDown(container.dispose);

      final profile = await waitUntilSettled(
        container,
        userProfileProvider,
      );

      expect(profile.hasError, isTrue);
    });

    test('invalidate re-subscribes to auth stream (retry recovery)', () async {
      final authRepo = RetryableAuthRepository((_) => Stream.value(null));

      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWith((ref) => authRepo),
        ],
      );
      addTearDown(container.dispose);

      await waitUntilSettled(container, authStateChangesProvider);
      expect(authRepo.subscribeCount, 1);

      container.invalidate(authStateChangesProvider);
      container.invalidate(userProfileProvider);

      await waitUntilSettled(container, authStateChangesProvider);
      expect(authRepo.subscribeCount, 2);
      expect(container.read(authStateChangesProvider).value, isNull);
    });
  });
}
