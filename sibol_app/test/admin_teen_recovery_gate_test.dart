import 'package:flutter_test/flutter_test.dart';
import 'package:sibol_app/features/admin/presentation/providers/admin_providers.dart';
import 'package:sibol_app/features/org/domain/entities/organization_membership.dart';

void main() {
  final now = DateTime(2026, 10, 27);

  test('org administrator membership qualifies for teen recovery gate', () {
    final membership = OrganizationMembership(
      membershipId: 'mbr_barangay03__uid',
      orgId: 'barangay03',
      accountUid: 'uid',
      status: MembershipStatus.active,
      capabilities: const ['org.manage_members', 'org.manage_roles'],
      createdAt: now,
      updatedAt: now,
    );
    expect(membershipIsOrgAdministrator(membership), isTrue);
  });

  test('ordinary staff membership does not qualify for teen recovery gate', () {
    final membership = OrganizationMembership(
      membershipId: 'mbr_barangay03__uid',
      orgId: 'barangay03',
      accountUid: 'uid',
      status: MembershipStatus.active,
      capabilities: const ['case.read'],
      createdAt: now,
      updatedAt: now,
    );
    expect(membershipIsOrgAdministrator(membership), isFalse);
  });
}
