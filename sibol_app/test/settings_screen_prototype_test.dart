import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sibol_app/core/permissions/sibol_role.dart';
import 'package:sibol_app/features/auth/domain/entities/auth_user.dart';
import 'package:sibol_app/features/auth/domain/entities/user_profile.dart';
import 'package:sibol_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:sibol_app/features/org/domain/entities/organization_membership.dart';
import 'package:sibol_app/features/org/presentation/providers/org_context_providers.dart';
import 'package:sibol_app/features/settings/presentation/screens/settings_screen.dart';
void main() {
  final now = DateTime(2026, 10, 26);
  Widget buildSettings({
    required UserProfile profile,
    List<OrganizationMembership> memberships = const [],
  }) {
    return ProviderScope(
      overrides: [
        authStateChangesProvider.overrideWith(
          (ref) => Stream.value(
            AuthUser(uid: 'uid-1', email: 'staff@sibol.local'),
          ),
        ),
        userProfileProvider.overrideWith((ref) => Stream.value(profile)),
        accountMembershipsProvider.overrideWith(
          (ref) => Stream.value(memberships),
        ),
      ],
      child: const MaterialApp(home: SettingsScreen()),
    );
  }

  testWidgets('UI-01 ordinary MOPH settings hide pending invitations', (tester) async {
    await tester.pumpWidget(
      buildSettings(
        profile: UserProfile(
          uid: 'uid-1',
          role: SibolRole.moph,
          displayName: 'MOPH Demo',
          active: true,
          createdAt: now,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Pending invitations'), findsNothing);
    expect(find.text('Change password'), findsOneWidget);
    expect(find.text('Staff management'), findsNothing);
  });

  testWidgets('UI-02 ordinary Barangay settings hide pending invitations', (tester) async {
    await tester.pumpWidget(
      buildSettings(
        profile: UserProfile(
          uid: 'uid-1',
          role: SibolRole.barangay,
          displayName: 'Barangay Demo',
          active: true,
          createdAt: now,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Pending invitations'), findsNothing);
    expect(find.text('Staff management'), findsNothing);
  });

  testWidgets('UI-04 org administrator sees staff management', (tester) async {
    await tester.pumpWidget(
      buildSettings(
        profile: UserProfile(
          uid: 'uid-1',
          role: SibolRole.barangay,
          displayName: 'Org Admin',
          active: true,
          createdAt: now,
          primaryOrgId: 'barangay03',
        ),
        memberships: [
          OrganizationMembership(
            membershipId: 'mbr_barangay03__uid-1',
            orgId: 'barangay03',
            accountUid: 'uid-1',
            status: MembershipStatus.active,
            capabilities: const [
              'org.manage_members',
              'org.manage_roles',
            ],
            createdAt: now,
            updatedAt: now,
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Staff management'), findsOneWidget);
    expect(find.text('Teen account recovery'), findsOneWidget);
    expect(find.text('Pending invitations'), findsNothing);
  });
}
