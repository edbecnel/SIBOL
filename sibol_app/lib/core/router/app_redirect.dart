import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sibol_app/core/constants/route_constants.dart';
import 'package:sibol_app/core/permissions/sibol_role.dart';
import 'package:sibol_app/features/auth/domain/entities/auth_user.dart';
import 'package:sibol_app/features/auth/domain/entities/user_profile.dart';

String? homeForRole(SibolRole role) {
  switch (role) {
    case SibolRole.teen:
      return Routes.teenHome;
    case SibolRole.barangay:
      return Routes.barangayHome;
    case SibolRole.moph:
      return Routes.mophHome;
  }
}

bool isRoleHome(String location, SibolRole role) {
  final home = homeForRole(role);
  return location == home || location.startsWith('$home/');
}

/// Pure redirect resolver for go_router; used by [appRouterProvider] and tests.
String? resolveAppRedirect({
  required String location,
  required AsyncValue<AuthUser?> authAsync,
  required AsyncValue<UserProfile?> profileAsync,
}) {
  final onLogin = location == Routes.login;
  final onSplash = location == Routes.splash;

  if (authAsync.isLoading) {
    return onSplash ? null : Routes.splash;
  }

  if (authAsync.hasError) {
    return onSplash ? null : Routes.splash;
  }

  final user = authAsync.value;
  if (user == null) {
    if (onLogin) return null;
    return Routes.login;
  }

  if (profileAsync.isLoading) {
    return onSplash ? null : Routes.splash;
  }

  if (profileAsync.hasError) {
    return onSplash ? null : Routes.splash;
  }

  final profile = profileAsync.value;

  if (profile == null || !profile.active) {
    if (location == Routes.unauthorized) return null;
    return Routes.unauthorized;
  }

  final home = homeForRole(profile.role);
  if (onLogin || onSplash) return home;

  if (location == Routes.settings) return null;

  if (!isRoleHome(location, profile.role) &&
      location != Routes.unauthorized &&
      location != Routes.settings) {
    return home;
  }

  if (isRoleHome(location, profile.role)) return null;

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
