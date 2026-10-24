import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sibol_app/core/providers/firebase_providers.dart';
import 'package:sibol_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:sibol_app/features/org/domain/org_context_resolver.dart';
import 'package:sibol_app/features/org/domain/entities/organization_membership.dart';
import 'package:sibol_app/features/org/data/repositories/organization_repository_impl.dart';
import 'package:sibol_app/features/org/domain/repositories/organization_repository.dart';

final organizationRepositoryProvider = Provider<OrganizationRepository>((ref) {
  return OrganizationRepositoryImpl(ref.watch(firestoreProvider));
});

final accountMembershipsProvider =
    StreamProvider<List<OrganizationMembership>>((ref) {
  final auth = ref.watch(authStateChangesProvider).value;
  if (auth == null) {
    return const Stream.empty();
  }
  return ref
      .watch(organizationRepositoryProvider)
      .watchMembershipsForAccount(auth.uid);
});

final barangayCaseOrgIdProvider = Provider<String?>((ref) {
  final profile = ref.watch(userProfileProvider).value;
  final memberships = ref.watch(accountMembershipsProvider).value ?? [];
  return OrgContextResolver.barangayOrgForCases(profile, memberships);
});

final barangayAssistanceOrgIdProvider = Provider<String?>((ref) {
  final profile = ref.watch(userProfileProvider).value;
  final memberships = ref.watch(accountMembershipsProvider).value ?? [];
  return OrgContextResolver.barangayOrgForAssistanceInbox(profile, memberships);
});

final barangayReportOrgIdProvider = Provider<String?>((ref) {
  final profile = ref.watch(userProfileProvider).value;
  final memberships = ref.watch(accountMembershipsProvider).value ?? [];
  return OrgContextResolver.barangayOrgForReports(profile, memberships);
});

final barangayCoordinationOrgIdProvider = Provider<String?>((ref) {
  final profile = ref.watch(userProfileProvider).value;
  final memberships = ref.watch(accountMembershipsProvider).value ?? [];
  return OrgContextResolver.barangayOrgForCoordination(profile, memberships);
});

final teenBarangayOrgIdProvider = Provider<String?>((ref) {
  final profile = ref.watch(userProfileProvider).value;
  final memberships = ref.watch(accountMembershipsProvider).value ?? [];
  return OrgContextResolver.teenSelectedBarangayOrg(profile, memberships);
});

final mophHospitalOrgIdProvider = Provider<String?>((ref) {
  final profile = ref.watch(userProfileProvider).value;
  final memberships = ref.watch(accountMembershipsProvider).value ?? [];
  return OrgContextResolver.mophHospitalOrg(profile, memberships);
});
