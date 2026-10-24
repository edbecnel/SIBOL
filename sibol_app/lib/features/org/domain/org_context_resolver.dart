import 'package:sibol_app/core/permissions/sibol_role.dart';
import 'package:sibol_app/features/auth/domain/entities/user_profile.dart';
import 'package:sibol_app/features/org/domain/entities/organization_membership.dart';
import 'package:sibol_app/features/org/domain/org_capabilities.dart';

/// Resolves authoritative organization ids from profile + memberships (never caller-supplied).
class OrgContextResolver {
  const OrgContextResolver._();

  static String? barangayOrgForCases(
    UserProfile? profile,
    List<OrganizationMembership> memberships,
  ) {
    return _resolveOrg(
      profile: profile,
      memberships: memberships,
      requiredCapability: OrgCapabilities.caseRead,
      role: SibolRole.barangay,
    );
  }

  static String? barangayOrgForAssistanceInbox(
    UserProfile? profile,
    List<OrganizationMembership> memberships,
  ) {
    return _resolveOrg(
      profile: profile,
      memberships: memberships,
      requiredCapability: OrgCapabilities.coordinationBarangay,
      role: SibolRole.barangay,
    );
  }

  static String? barangayOrgForReports(
    UserProfile? profile,
    List<OrganizationMembership> memberships,
  ) {
    return _resolveOrg(
      profile: profile,
      memberships: memberships,
      requiredCapability: OrgCapabilities.reportSubmit,
      role: SibolRole.barangay,
    );
  }

  static String? barangayOrgForCoordination(
    UserProfile? profile,
    List<OrganizationMembership> memberships,
  ) {
    return _resolveOrg(
      profile: profile,
      memberships: memberships,
      requiredCapability: OrgCapabilities.coordinationBarangay,
      role: SibolRole.barangay,
    );
  }

  static String? teenSelectedBarangayOrg(
    UserProfile? profile,
    List<OrganizationMembership> memberships,
  ) {
    if (profile == null || profile.role != SibolRole.teen) return null;
    final selected = profile.selectedBarangayOrgId;
    if (selected == null || selected.isEmpty) return null;
    if (!_isValidOrgId(selected)) return null;
    return selected;
  }

  /// MOPH hospital org for inbox/rules (coordination.hospital on hospital org).
  static String? mophHospitalOrg(
    UserProfile? profile,
    List<OrganizationMembership> memberships,
  ) {
    if (profile == null || profile.role != SibolRole.moph || !profile.active) {
      return null;
    }
    final primary = profile.primaryOrgId;
    if (primary != null &&
        primary.isNotEmpty &&
        _membershipGrants(primary, memberships, OrgCapabilities.coordinationHospital)) {
      return primary;
    }
    final matches = _activeMembershipsWith(
      memberships,
      OrgCapabilities.coordinationHospital,
    );
    if (matches.length == 1) return matches.first.orgId;
    return null;
  }

  static String? _resolveOrg({
    required UserProfile? profile,
    required List<OrganizationMembership> memberships,
    required String requiredCapability,
    required SibolRole role,
  }) {
    if (profile == null || profile.role != role || !profile.active) return null;
    final primary = profile.primaryOrgId;
    if (primary != null && primary.isNotEmpty) {
      if (_membershipGrants(primary, memberships, requiredCapability)) {
        return primary;
      }
      return null;
    }
    final matches =
        _activeMembershipsWith(memberships, requiredCapability);
    if (matches.length == 1) return matches.first.orgId;
    return null;
  }

  static List<OrganizationMembership> _activeMembershipsWith(
    List<OrganizationMembership> memberships,
    String capability,
  ) {
    return memberships
        .where(
          (m) =>
              m.status == MembershipStatus.active &&
              m.hasCapability(capability) &&
              _isValidOrgId(m.orgId),
        )
        .toList();
  }

  static bool _membershipGrants(
    String orgId,
    List<OrganizationMembership> memberships,
    String capability,
  ) {
    if (!_isValidOrgId(orgId)) return false;
    return memberships.any(
      (m) =>
          m.orgId == orgId &&
          m.status == MembershipStatus.active &&
          m.hasCapability(capability),
    );
  }

  static bool _isValidOrgId(String orgId) {
    return RegExp(r'^org[0-9A-Za-z]{22}$').hasMatch(orgId);
  }
}
