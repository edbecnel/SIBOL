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
    bool mustChangePassword = false,
  }) {
    return UserProfile(
      uid: 'u1',
      role: role,
      displayName: 'Demo',
      active: active,
      createdAt: DateTime(2026),
      mustChangePassword: mustChangePassword,
    );
  }

  group('resolveAppRedirect', () {
    test('signed-out on splash → welcome', () {
      expect(
        resolveAppRedirect(
          location: Routes.splash,
          authAsync: const AsyncData(null),
          profileAsync: const AsyncData(null),
        ),
        Routes.welcome,
      );
    });

    test('profile loading does not block signed-out navigation', () {
      expect(
        resolveAppRedirect(
          location: Routes.splash,
          authAsync: const AsyncData(null),
          profileAsync: const AsyncLoading(),
        ),
        Routes.welcome,
      );
    });

    test('signed-out already on welcome → stay', () {
      expect(
        resolveAppRedirect(
          location: Routes.welcome,
          authAsync: const AsyncData(null),
          profileAsync: const AsyncData(null),
        ),
        isNull,
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

    test('authenticated missing profile → account not provisioned', () {
      expect(
        resolveAppRedirect(
          location: Routes.splash,
          authAsync: const AsyncData(user),
          profileAsync: const AsyncData(null),
        ),
        Routes.accountNotProvisioned,
      );
    });

    test('authenticated missing profile on teen register → stay', () {
      expect(
        resolveAppRedirect(
          location: Routes.teenRegister,
          authAsync: const AsyncData(user),
          profileAsync: const AsyncData(null),
        ),
        isNull,
      );
    });

    test('profile loading on teen register → stay', () {
      expect(
        resolveAppRedirect(
          location: Routes.teenRegister,
          authAsync: const AsyncData(user),
          profileAsync: const AsyncLoading(),
        ),
        isNull,
      );
    });

    test('profile loading on verify-email route → stay', () {
      expect(
        resolveAppRedirect(
          location: Routes.teenRegisterVerifyEmail,
          authAsync: const AsyncData(user),
          profileAsync: const AsyncLoading(),
        ),
        isNull,
      );
    });

    test('teen self-registration intent on splash → teen register', () {
      expect(
        resolveAppRedirect(
          location: Routes.splash,
          authAsync: const AsyncData(user),
          profileAsync: const AsyncData(null),
          teenSelfRegistrationInProgress: true,
        ),
        Routes.teenRegister,
      );
    });

    test('authenticated missing profile on login → account not provisioned', () {
      expect(
        resolveAppRedirect(
          location: Routes.login,
          authAsync: const AsyncData(user),
          profileAsync: const AsyncData(null),
        ),
        Routes.accountNotProvisioned,
      );
    });

    test('teen intent on login with missing profile → teen register', () {
      expect(
        resolveAppRedirect(
          location: Routes.login,
          authAsync: const AsyncData(user),
          profileAsync: const AsyncData(null),
          teenSelfRegistrationInProgress: true,
        ),
        Routes.teenRegister,
      );
    });

    test('profile loading on login → stay', () {
      expect(
        resolveAppRedirect(
          location: Routes.login,
          authAsync: const AsyncData(user),
          profileAsync: const AsyncLoading(),
        ),
        isNull,
      );
    });

    test('staff without intent on splash → account not provisioned', () {
      expect(
        resolveAppRedirect(
          location: Routes.splash,
          authAsync: const AsyncData(user),
          profileAsync: const AsyncData(null),
          teenSelfRegistrationInProgress: false,
        ),
        Routes.accountNotProvisioned,
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

    test('mustChangePassword redirects to change password', () {
      expect(
        resolveAppRedirect(
          location: Routes.barangayHome,
          authAsync: const AsyncData(user),
          profileAsync: AsyncData(
            profile(role: SibolRole.barangay, mustChangePassword: true),
          ),
        ),
        Routes.changePassword,
      );
      expect(
        resolveAppRedirect(
          location: Routes.changePassword,
          authAsync: const AsyncData(user),
          profileAsync: AsyncData(
            profile(role: SibolRole.barangay, mustChangePassword: true),
          ),
        ),
        isNull,
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

    test('barangay on case detail route → stay', () {
      expect(
        resolveAppRedirect(
          location: Routes.barangayCaseDetail('demo-case-001'),
          authAsync: const AsyncData(user),
          profileAsync: AsyncData(profile(role: SibolRole.barangay)),
        ),
        isNull,
      );
    });

    test('teen on assistance list → stay', () {
      expect(
        resolveAppRedirect(
          location: Routes.teenAssistanceList,
          authAsync: const AsyncData(user),
          profileAsync: AsyncData(profile(role: SibolRole.teen)),
        ),
        isNull,
      );
    });

    test('teen on assistance new → stay', () {
      expect(
        resolveAppRedirect(
          location: Routes.teenAssistanceNew,
          authAsync: const AsyncData(user),
          profileAsync: AsyncData(profile(role: SibolRole.teen)),
        ),
        isNull,
      );
    });

    test('barangay on incoming requests → stay', () {
      expect(
        resolveAppRedirect(
          location: Routes.barangayIncomingRequests,
          authAsync: const AsyncData(user),
          profileAsync: AsyncData(profile(role: SibolRole.barangay)),
        ),
        isNull,
      );
    });

    test('teen on barangay incoming requests → teen home', () {
      expect(
        resolveAppRedirect(
          location: Routes.barangayIncomingRequests,
          authAsync: const AsyncData(user),
          profileAsync: AsyncData(profile(role: SibolRole.teen)),
        ),
        Routes.teenHome,
      );
    });

    test('barangay on teen assistance → barangay home', () {
      expect(
        resolveAppRedirect(
          location: Routes.teenAssistanceList,
          authAsync: const AsyncData(user),
          profileAsync: AsyncData(profile(role: SibolRole.barangay)),
        ),
        Routes.barangayHome,
      );
    });

    test('teen on barangay case detail → teen home', () {
      expect(
        resolveAppRedirect(
          location: Routes.barangayCaseDetail('demo-case-001'),
          authAsync: const AsyncData(user),
          profileAsync: AsyncData(profile(role: SibolRole.teen)),
        ),
        Routes.teenHome,
      );
    });

    test('barangay on case create route → stay', () {
      expect(
        resolveAppRedirect(
          location: Routes.barangayCaseCreate,
          authAsync: const AsyncData(user),
          profileAsync: AsyncData(profile(role: SibolRole.barangay)),
        ),
        isNull,
      );
    });

    test('barangay on case edit route → stay', () {
      expect(
        resolveAppRedirect(
          location: Routes.barangayCaseEdit('demo-case-001'),
          authAsync: const AsyncData(user),
          profileAsync: AsyncData(profile(role: SibolRole.barangay)),
        ),
        isNull,
      );
    });

    test('teen on settings → stay', () {
      expect(
        resolveAppRedirect(
          location: Routes.settings,
          authAsync: const AsyncData(user),
          profileAsync: AsyncData(profile(role: SibolRole.teen)),
        ),
        isNull,
      );
    });

    test('teen on profile editor route → stay', () {
      expect(
        resolveAppRedirect(
          location: Routes.teenProfileEdit,
          authAsync: const AsyncData(user),
          profileAsync: AsyncData(profile(role: SibolRole.teen)),
        ),
        isNull,
      );
    });

    test('barangay on teen profile editor → barangay home', () {
      expect(
        resolveAppRedirect(
          location: Routes.teenProfileEdit,
          authAsync: const AsyncData(user),
          profileAsync: AsyncData(profile(role: SibolRole.barangay)),
        ),
        Routes.barangayHome,
      );
    });

    test('moph on barangay case detail → moph home', () {
      expect(
        resolveAppRedirect(
          location: Routes.barangayCaseDetail('demo-case-001'),
          authAsync: const AsyncData(user),
          profileAsync: AsyncData(profile(role: SibolRole.moph)),
        ),
        Routes.mophHome,
      );
    });

    test('authenticated central admin → settings home', () {
      expect(
        resolveAppRedirect(
          location: Routes.splash,
          authAsync: const AsyncData(user),
          profileAsync: AsyncData(
            UserProfile(
              uid: 'u1',
              role: SibolRole.barangay,
              displayName: 'Admin',
              active: true,
              createdAt: DateTime(2026),
              isCentralAdmin: true,
            ),
          ),
        ),
        Routes.settings,
      );
    });
  });
}
