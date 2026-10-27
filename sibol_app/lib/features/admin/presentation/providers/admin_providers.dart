import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sibol_app/features/admin/data/admin_api.dart';
import 'package:sibol_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:sibol_app/features/org/domain/entities/organization_membership.dart';
import 'package:sibol_app/features/org/domain/org_capabilities.dart';
import 'package:sibol_app/features/org/presentation/providers/org_context_providers.dart';

final adminApiProvider = Provider<AdminApi>((ref) {
  return AdminApi(FirebaseFunctions.instance);
});

final isCentralAdminProvider = Provider<bool>((ref) {
  return ref.watch(userProfileProvider).value?.isCentralAdmin ?? false;
});

bool membershipIsOrgAdministrator(OrganizationMembership membership) {
  return membership.status == MembershipStatus.active &&
      membership.hasCapability(OrgCapabilities.orgManageMembers) &&
      membership.hasCapability(OrgCapabilities.orgManageRoles);
}

final orgAdminManagedOrgIdsProvider = Provider<List<String>>((ref) {
  final memberships = ref.watch(accountMembershipsProvider).value ?? [];
  return memberships
      .where(membershipIsOrgAdministrator)
      .map((m) => m.orgId)
      .toList();
});

final canAccessAdministrationProvider = Provider<bool>((ref) {
  if (ref.watch(isCentralAdminProvider)) return true;
  return ref.watch(orgAdminManagedOrgIdsProvider).isNotEmpty;
});

/// Barangay org administrators (not hospital org admins on the MOPH home).
final canAccessBarangayTeenRecoveryProvider = Provider<bool>((ref) {
  if (ref.watch(isCentralAdminProvider)) return false;
  return ref.watch(orgAdminManagedOrgIdsProvider).isNotEmpty;
});
