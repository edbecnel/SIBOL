import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sibol_app/core/constants/route_constants.dart';
import 'package:sibol_app/core/permissions/sibol_role.dart';
import 'package:sibol_app/features/auth/domain/entities/auth_user.dart';
import 'package:sibol_app/features/auth/domain/entities/user_profile.dart';

String homeForRole(SibolRole role) {
  switch (role) {
    case SibolRole.teen:
      return Routes.teenHome;
    case SibolRole.barangay:
      return Routes.barangayHome;
    case SibolRole.moph:
      return Routes.mophHome;
  }
}

String homeForProfile(UserProfile profile) {
  if (profile.isCentralAdmin) {
    return Routes.settings;
  }
  return homeForRole(profile.role);
}

bool isTeenRegistrationRoute(String location) {
  return location == Routes.teenRegister ||
      location == Routes.teenRegisterVerifyEmail ||
      location == Routes.teenRegisterComplete ||
      location.startsWith('${Routes.teenRegister}/');
}

bool isPublicUnauthenticatedRoute(String location) {
  return location == Routes.welcome ||
      location == Routes.login ||
      location == Routes.passwordReset ||
      isTeenRegistrationRoute(location);
}

bool isRoleHome(String location, SibolRole role) {
  final home = homeForRole(role);
  return location == home || location.startsWith('$home/');
}

bool isProfileHome(String location, UserProfile profile) {
  final home = homeForProfile(profile);
  return location == home || location.startsWith('$home/');
}

/// Pure redirect resolver for go_router; used by [appRouterProvider] and tests.
String? resolveAppRedirect({
  required String location,
  required AsyncValue<AuthUser?> authAsync,
  required AsyncValue<UserProfile?> profileAsync,
  bool teenSelfRegistrationInProgress = false,
}) {
  final onSplash = location == Routes.splash;
  final onWelcome = location == Routes.welcome;
  final onLogin = location == Routes.login;
  final onPasswordReset = location == Routes.passwordReset;
  final onTeenRegister = isTeenRegistrationRoute(location);
  final onAccountNotProvisioned = location == Routes.accountNotProvisioned;

  if (authAsync.isLoading) {
    return onSplash ? null : Routes.splash;
  }

  if (authAsync.hasError) {
    return onSplash ? null : Routes.splash;
  }

  final user = authAsync.value;
  if (user == null) {
    if (isPublicUnauthenticatedRoute(location)) return null;
    return Routes.welcome;
  }

  if (profileAsync.isLoading) {
    if (onSplash ||
        onAccountNotProvisioned ||
        onTeenRegister ||
        onPasswordReset) {
      return null;
    }
    return Routes.splash;
  }

  if (profileAsync.hasError) {
    return onSplash ? null : Routes.splash;
  }

  final profile = profileAsync.value;

  if (profile == null) {
    if (onTeenRegister || onPasswordReset) return null;
    if (teenSelfRegistrationInProgress) {
      if (onSplash || onAccountNotProvisioned) return Routes.teenRegister;
    }
    if (onLogin || onWelcome || onAccountNotProvisioned) return null;
    return Routes.accountNotProvisioned;
  }

  if (!profile.active) {
    if (location == Routes.unauthorized) return null;
    return Routes.unauthorized;
  }

  final home = homeForProfile(profile);
  if (onLogin || onSplash || onWelcome || onAccountNotProvisioned) return home;

  if (location == Routes.settings) return null;

  if (onTeenRegister && profile.role == SibolRole.teen) {
    return home;
  }

  if (profile.isCentralAdmin) {
    if (location.startsWith('/admin') || location == Routes.settings) return null;
  }

  if (!isProfileHome(location, profile) &&
      location != Routes.unauthorized &&
      location != Routes.settings &&
      !location.startsWith('/admin')) {
    return home;
  }

  if (isProfileHome(location, profile)) return null;

  if (location == Routes.teenHome && profile.role != SibolRole.teen) {
    return home;
  }
  if (location == Routes.barangayHome && profile.role != SibolRole.barangay) {
    return home;
  }
  if (location == Routes.mophHome && profile.role != SibolRole.moph) {
    return home;
  }

  return null;
}
