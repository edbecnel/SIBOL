import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sibol_app/core/constants/route_constants.dart';
import 'package:sibol_app/core/router/app_navigator_key.dart';
import 'package:sibol_app/core/router/app_redirect.dart';
import 'package:sibol_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:sibol_app/features/auth/presentation/screens/login_screen.dart';
import 'package:sibol_app/features/auth/presentation/screens/splash_screen.dart';
import 'package:sibol_app/features/cases/presentation/screens/barangay_home_screen.dart';
import 'package:sibol_app/features/moph/presentation/screens/moph_home_screen.dart';
import 'package:sibol_app/features/settings/presentation/screens/settings_screen.dart';
import 'package:sibol_app/features/teenager/presentation/screens/teen_home_screen.dart';
import 'package:sibol_app/features/auth/presentation/screens/unauthorized_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: Routes.splash,
    refreshListenable: _RouterRefresh(ref),
    redirect: (context, state) {
      return resolveAppRedirect(
        location: state.matchedLocation,
        authAsync: ref.read(authStateChangesProvider),
        profileAsync: ref.read(userProfileProvider),
      );
    },
    routes: [
      GoRoute(
        path: Routes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: Routes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: Routes.unauthorized,
        builder: (context, state) => const UnauthorizedScreen(),
      ),
      GoRoute(
        path: Routes.teenHome,
        builder: (context, state) => const TeenHomeScreen(),
      ),
      GoRoute(
        path: Routes.barangayHome,
        builder: (context, state) => const BarangayHomeScreen(),
      ),
      GoRoute(
        path: Routes.mophHome,
        builder: (context, state) => const MophHomeScreen(),
      ),
      GoRoute(
        path: Routes.settings,
        builder: (context, state) => const SettingsScreen(),
      ),
    ],
  );
});

class _RouterRefresh extends ChangeNotifier {
  _RouterRefresh(this._ref) {
    _ref.listen(authStateChangesProvider, (_, __) => notifyListeners());
    _ref.listen(userProfileProvider, (_, __) => notifyListeners());
  }

  final Ref _ref;
}
