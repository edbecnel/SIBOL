import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sibol_app/core/permissions/sibol_role.dart';
import 'package:sibol_app/features/auth/domain/entities/user_profile.dart';
import 'package:sibol_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:sibol_app/core/providers/firebase_providers.dart';
import 'package:sibol_app/features/auth/domain/entities/auth_user.dart';
import 'package:sibol_app/features/cases/presentation/screens/barangay_home_screen.dart';
import 'support/fake_case_repository.dart';
import 'package:sibol_app/features/org/domain/entities/organization_membership.dart';
import 'package:sibol_app/features/org/domain/org_capabilities.dart';
import 'package:sibol_app/features/org/presentation/providers/org_context_providers.dart';

const _orgId = 'barangay03';
const _uid = 'WZj7Seh3qNUlGfnDaYbL1RBA4bNV';

UserProfile _barangayProfile({String? primaryOrgId}) {
  return UserProfile(
    uid: _uid,
    role: SibolRole.barangay,
    displayName: 'Demo Barangay Org Administrator',
    active: true,
    createdAt: DateTime(2026),
    primaryOrgId: primaryOrgId,
  );
}

OrganizationMembership _membership(List<String> capabilities) {
  final now = DateTime(2026);
  return OrganizationMembership(
    membershipId: 'mbr_${_orgId}__$_uid',
    orgId: _orgId,
    accountUid: _uid,
    status: MembershipStatus.active,
    capabilities: capabilities,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> pumpDashboard(
    WidgetTester tester, {
    required UserProfile profile,
    required List<OrganizationMembership> memberships,
  }) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authStateChangesProvider.overrideWith(
            (ref) => Stream.value(
              AuthUser(uid: _uid, email: 'barangay.org.admin@sibol.local'),
            ),
          ),
          userProfileProvider.overrideWith(
            (ref) => Stream.value(profile),
          ),
          accountMembershipsProvider.overrideWith(
            (ref) => Stream.value(memberships),
          ),
          caseRepositoryProvider.overrideWithValue(FakeCaseRepository()),
        ],
        child: const MaterialApp(home: BarangayHomeScreen()),
      ),
    );
    await tester.pumpAndSettle();
    tester.view.resetPhysicalSize();
  }

  testWidgets('management-only admin loads without case StateError', (tester) async {
    await pumpDashboard(
      tester,
      profile: _barangayProfile(primaryOrgId: _orgId),
      memberships: [
        _membership([
          OrgCapabilities.orgManageMembers,
          OrgCapabilities.orgManageRoles,
        ]),
      ],
    );

    expect(find.textContaining('Bad state'), findsNothing);
    expect(find.text('Organization administration'), findsOneWidget);
    expect(find.text('Staff management'), findsOneWidget);
    expect(find.textContaining('Operational case access is not assigned'), findsOneWidget);
    expect(find.widgetWithIcon(FloatingActionButton, Icons.add), findsNothing);
    final incoming = find.widgetWithText(OutlinedButton, 'Incoming requests');
    final button = tester.widget<OutlinedButton>(incoming);
    expect(button.onPressed, isNull);
  });

  testWidgets('operational staff sees case list section without admin card', (tester) async {
    await pumpDashboard(
      tester,
      profile: _barangayProfile(primaryOrgId: _orgId),
      memberships: [
        _membership([
          OrgCapabilities.caseRead,
          OrgCapabilities.caseWrite,
          OrgCapabilities.reportSubmit,
          OrgCapabilities.coordinationBarangay,
        ]),
      ],
    );

    expect(find.text('Organization administration'), findsNothing);
    expect(find.textContaining('No demonstration cases yet'), findsOneWidget);
    expect(find.widgetWithIcon(FloatingActionButton, Icons.add), findsOneWidget);
    final incoming = find.widgetWithText(OutlinedButton, 'Incoming requests');
    expect(tester.widget<OutlinedButton>(incoming).onPressed, isNotNull);
  });

  testWidgets('dual-capability account shows administration and operations', (tester) async {
    await pumpDashboard(
      tester,
      profile: _barangayProfile(primaryOrgId: _orgId),
      memberships: [
        _membership([
          OrgCapabilities.orgManageMembers,
          OrgCapabilities.orgManageRoles,
          OrgCapabilities.caseRead,
          OrgCapabilities.coordinationBarangay,
        ]),
      ],
    );

    expect(find.text('Organization administration'), findsOneWidget);
    expect(find.textContaining('No demonstration cases yet'), findsOneWidget);
    expect(find.widgetWithIcon(FloatingActionButton, Icons.add), findsNothing);
  });

  testWidgets('suspended membership denies operational actions', (tester) async {
    final now = DateTime(2026);
    await pumpDashboard(
      tester,
      profile: _barangayProfile(primaryOrgId: _orgId),
      memberships: [
        OrganizationMembership(
          membershipId: 'mbr_${_orgId}__$_uid',
          orgId: _orgId,
          accountUid: _uid,
          status: MembershipStatus.suspended,
          capabilities: [OrgCapabilities.caseRead],
          createdAt: now,
          updatedAt: now,
        ),
      ],
    );

    expect(find.textContaining('Operational case access is not authorized'), findsOneWidget);
    expect(find.textContaining('Loading fictional cases'), findsNothing);
  });
}
