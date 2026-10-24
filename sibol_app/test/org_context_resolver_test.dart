import 'package:flutter_test/flutter_test.dart';
import 'package:sibol_app/core/permissions/sibol_role.dart';
import 'package:sibol_app/features/auth/domain/entities/user_profile.dart';
import 'package:sibol_app/features/org/domain/entities/organization_membership.dart';
import 'package:sibol_app/features/org/domain/org_capabilities.dart';
import 'package:sibol_app/features/org/domain/org_context_resolver.dart';

const orgA = 'barangay03';
const orgB = 'barangay99';

UserProfile _profile({
  SibolRole role = SibolRole.barangay,
  String? primaryOrgId,
  String? selectedBarangayOrgId,
  bool active = true,
}) {
  return UserProfile(
    uid: 'u1',
    role: role,
    displayName: 'Demo',
    active: active,
    createdAt: DateTime(2026),
    primaryOrgId: primaryOrgId,
    selectedBarangayOrgId: selectedBarangayOrgId,
  );
}

OrganizationMembership _membership(String orgId, List<String> caps,
    {MembershipStatus status = MembershipStatus.active}) {
  final now = DateTime(2026);
  return OrganizationMembership(
    membershipId: 'mbr_${orgId}__u1',
    orgId: orgId,
    accountUid: 'u1',
    status: status,
    capabilities: caps,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  test('barangay case org uses primaryOrgId when membership grants case.read', () {
    final org = OrgContextResolver.barangayOrgForCases(
      _profile(primaryOrgId: orgA),
      [_membership(orgA, [OrgCapabilities.caseRead, OrgCapabilities.caseWrite])],
    );
    expect(org, orgA);
  });

  test('barangay case org denies cross-org primary without membership', () {
    final org = OrgContextResolver.barangayOrgForCases(
      _profile(primaryOrgId: orgB),
      [_membership(orgA, [OrgCapabilities.caseRead])],
    );
    expect(org, isNull);
  });

  test('barangay case org resolves single membership when primary missing', () {
    final org = OrgContextResolver.barangayOrgForCases(
      _profile(),
      [_membership(orgA, [OrgCapabilities.caseRead])],
    );
    expect(org, orgA);
  });

  test('barangay case org null when capability missing', () {
    final org = OrgContextResolver.barangayOrgForCases(
      _profile(primaryOrgId: orgA),
      [_membership(orgA, [OrgCapabilities.orgManageMembers])],
    );
    expect(org, isNull);
  });

  test('barangay case org null when membership suspended', () {
    final org = OrgContextResolver.barangayOrgForCases(
      _profile(primaryOrgId: orgA),
      [
        _membership(
          orgA,
          [OrgCapabilities.caseRead],
          status: MembershipStatus.suspended,
        ),
      ],
    );
    expect(org, isNull);
  });

  test('moph hospital org requires coordination.hospital', () {
    final org = OrgContextResolver.mophHospitalOrg(
      _profile(role: SibolRole.moph, primaryOrgId: orgB),
      [_membership(orgB, [OrgCapabilities.coordinationHospital])],
    );
    expect(org, orgB);
  });

  test('teen selected barangay org from profile', () {
    final org = OrgContextResolver.teenSelectedBarangayOrg(
      _profile(
        role: SibolRole.teen,
        selectedBarangayOrgId: orgA,
      ),
      [],
    );
    expect(org, orgA);
  });
}
