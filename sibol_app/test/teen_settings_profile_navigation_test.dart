import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:sibol_app/core/constants/route_constants.dart';
import 'package:sibol_app/core/permissions/sibol_role.dart';
import 'package:sibol_app/core/router/app_redirect.dart';
import 'package:sibol_app/features/auth/domain/entities/auth_user.dart';
import 'package:sibol_app/features/auth/domain/entities/user_profile.dart';
import 'package:sibol_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:sibol_app/features/settings/presentation/screens/settings_screen.dart';
import 'package:sibol_app/features/settings/presentation/screens/teen_profile_edit_screen.dart';
import 'package:sibol_app/features/teenager/presentation/screens/teen_home_screen.dart';

void main() {
  testWidgets('Settings → Edit my profile opens teen profile editor', (tester) async {
    const user = AuthUser(uid: 'teen-1', email: 'teen@sibol.local');
    final teenProfile = UserProfile(
      uid: 'teen-1',
      role: SibolRole.teen,
      displayName: 'QA Teen',
      active: true,
      createdAt: DateTime(2026),
      dateOfBirth: '2010-03-15',
      assignedBarangay: 'Barangay 3, Balingasag',
      contactEmail: 'contact@sibol.local',
      contactPhone: '+639171234567',
    );

    final router = GoRouter(
      initialLocation: Routes.settings,
      redirect: (context, state) => resolveAppRedirect(
        location: state.matchedLocation,
        authAsync: const AsyncData(user),
        profileAsync: AsyncData(teenProfile),
      ),
      routes: [
        GoRoute(
          path: Routes.teenHome,
          builder: (context, state) => const TeenHomeScreen(),
        ),
        GoRoute(
          path: Routes.settings,
          builder: (context, state) => const SettingsScreen(),
          routes: [
            GoRoute(
              path: 'profile',
              builder: (context, state) => const TeenProfileEditScreen(),
            ),
          ],
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authStateChangesProvider.overrideWith((ref) => Stream.value(user)),
          userProfileProvider.overrideWith((ref) => Stream.value(teenProfile)),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Settings'), findsOneWidget);
    await tester.tap(find.text('Edit my profile'));
    await tester.pumpAndSettle();

    expect(find.text('My profile'), findsOneWidget);
    expect(find.text('QA Teen'), findsOneWidget);
    expect(find.text('2010-03-15'), findsOneWidget);
    expect(find.text('Barangay 3, Balingasag'), findsOneWidget);
    expect(find.text('contact@sibol.local'), findsOneWidget);
    expect(find.text('Teenager dashboard'), findsNothing);
  });
}
