import 'package:sibol_app/features/org/domain/entities/organization.dart';
import 'package:sibol_app/features/org/domain/entities/organization_membership.dart';

abstract class OrganizationRepository {
  Stream<Organization?> watchOrganization(String orgId);

  Future<Organization?> fetchOrganization(String orgId);

  /// Rules-compatible listen on `organizationMemberships/mbr_{orgId}__{accountUid}`.
  Stream<List<OrganizationMembership>> watchMembershipForOrg({
    required String orgId,
    required String accountUid,
  });

  Future<OrganizationMembership?> fetchMembership(String membershipId);
}
