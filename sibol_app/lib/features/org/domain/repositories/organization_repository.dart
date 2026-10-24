import 'package:sibol_app/features/org/domain/entities/organization.dart';
import 'package:sibol_app/features/org/domain/entities/organization_membership.dart';

abstract class OrganizationRepository {
  Stream<Organization?> watchOrganization(String orgId);

  Future<Organization?> fetchOrganization(String orgId);

  Stream<List<OrganizationMembership>> watchMembershipsForAccount(String accountUid);

  Future<OrganizationMembership?> fetchMembership(String membershipId);
}
