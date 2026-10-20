import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sibol_app/core/constants/route_constants.dart';
import 'package:sibol_app/core/permissions/sibol_role.dart';
import 'package:sibol_app/core/router/app_redirect.dart';
import 'package:sibol_app/features/auth/domain/entities/auth_user.dart';
import 'package:sibol_app/features/auth/domain/entities/user_profile.dart';

void main() {
  const user = AuthUser(uid: 'u1', email: 'demo@example.com');

  UserProfile profile({
    SibolRole role = SibolRole.barangay,
    bool active = true,
  }) {
    return UserProfile(
      uid: 'u1',
      role: role,
      displayName: 'Demo',
      active: active,
      createdAt: DateTime(2026),
    );
  }

  group('resolveAppRedirect', () {
    test('signed-out on splash → login', () {
      expect(
        resolveAppRedirect(
          location: Routes.splash,
          authAsync: const AsyncData(null),
          profileAsync: const AsyncData(null),
        ),
        Routes.login,
      );
    });

    test('profile loading does not block signed-out navigation', () {
      expect(
        resolveAppRedirect(
          location: Routes.splash,
          authAsync: const AsyncData(null),
          profileAsync: const AsyncLoading(),
        ),
        Routes.login,
      );
    });

    test('signed-out already on login → stay', () {
      expect(
        resolveAppRedirect(
          location: Routes.login,
          authAsync: const AsyncData(null),
          profileAsync: const AsyncData(null),
        ),
        isNull,
      );
    });

    test('auth loading → splash', () {
      expect(
        resolveAppRedirect(
          location: Routes.login,
          authAsync: const AsyncLoading(),
          profileAsync: const AsyncData(null),
        ),
        Routes.splash,
      );
    });

    test('authenticated missing profile → unauthorized', () {
      expect(
        resolveAppRedirect(
          location: Routes.splash,
          authAsync: const AsyncData(user),
          profileAsync: const AsyncData(null),
        ),
        Routes.unauthorized,
      );
    });

    test('authenticated inactive profile → unauthorized', () {
      expect(
        resolveAppRedirect(
          location: Routes.splash,
          authAsync: const AsyncData(user),
          profileAsync: AsyncData(profile(active: false)),
        ),
        Routes.unauthorized,
      );
    });

    test('authenticated active barangay → barangay home', () {
      expect(
        resolveAppRedirect(
          location: Routes.splash,
          authAsync: const AsyncData(user),
          profileAsync: AsyncData(profile(role: SibolRole.barangay)),
        ),
        Routes.barangayHome,
      );
    });

    test('authenticated active teen → teen home', () {
      expect(
        resolveAppRedirect(
          location: Routes.splash,
          authAsync: const AsyncData(user),
          profileAsync: AsyncData(profile(role: SibolRole.teen)),
        ),
        Routes.teenHome,
      );
    });

    test('authenticated active moph → moph home', () {
      expect(
        resolveAppRedirect(
          location: Routes.splash,
          authAsync: const AsyncData(user),
          profileAsync: AsyncData(profile(role: SibolRole.moph)),
        ),
        Routes.mophHome,
      );
    });

    test('auth error stays on splash', () {
      expect(
        resolveAppRedirect(
          location: Routes.login,
          authAsync: AsyncError(Exception('fail'), StackTrace.empty),
          profileAsync: const AsyncData(null),
        ),
        Routes.splash,
      );
    });

    test('profile error stays on splash', () {
      expect(
        resolveAppRedirect(
          location: Routes.login,
          authAsync: const AsyncData(user),
          profileAsync: AsyncError(Exception('fail'), StackTrace.empty),
        ),
        Routes.splash,
      );
    });

    test('auth error already on splash → stay', () {
      expect(
        resolveAppRedirect(
          location: Routes.splash,
          authAsync: AsyncError(Exception('fail'), StackTrace.empty),
          profileAsync: const AsyncLoading(),
        ),
        isNull,
      );
    });
  });
}
