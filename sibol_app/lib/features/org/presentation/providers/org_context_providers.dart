import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sibol_app/core/constants/demo_org_constants.dart';
import 'package:sibol_app/core/permissions/sibol_role.dart';
import 'package:sibol_app/core/providers/firebase_providers.dart';
import 'package:sibol_app/features/auth/domain/entities/user_profile.dart';
import 'package:sibol_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:sibol_app/features/org/domain/barangay_organization_presentation.dart';
import 'package:sibol_app/features/org/domain/org_capabilities.dart';
import 'package:sibol_app/features/org/presentation/providers/organization_presentation_providers.dart';
import 'package:sibol_app/features/org/domain/org_context_resolver.dart';
import 'package:sibol_app/features/org/domain/entities/organization_membership.dart';
import 'package:sibol_app/features/org/data/repositories/organization_repository_impl.dart';
import 'package:sibol_app/features/org/domain/repositories/organization_repository.dart';

final organizationRepositoryProvider = Provider<OrganizationRepository>((ref) {
  return OrganizationRepositoryImpl(ref.watch(firestoreProvider));
});

/// Org id for the canonical membership document stream (primaryOrgId, or pilot hospital for MOPH).
String? membershipListenOrgIdForStaff(UserProfile profile) {
  final primary = profile.primaryOrgId?.trim();
  if (primary != null && primary.isNotEmpty) {
    return primary;
  }
  if (profile.role == SibolRole.moph) {
    return DemoOrgConstants.hospitalOrgId;
  }
  return null;
}

final accountMembershipsProvider =
    StreamProvider<List<OrganizationMembership>>((ref) {
  final auth = ref.watch(authStateChangesProvider).value;
  final profile = ref.watch(userProfileProvider).value;
  if (auth == null || profile == null) {
    return Stream.value(const []);
  }
  if (profile.role == SibolRole.teen) {
    return Stream.value(const []);
  }
  final listenOrgId = membershipListenOrgIdForStaff(profile);
  if (listenOrgId == null) {
    return Stream.value(const []);
  }
  return ref.watch(organizationRepositoryProvider).watchMembershipForOrg(
        orgId: listenOrgId,
        accountUid: auth.uid,
      );
});

/// Hospital coordination context for MOPH dashboard queries (after profile + membership load).
final mophOperationalContextProvider = Provider<AsyncValue<String>>((ref) {
  final profileAsync = ref.watch(userProfileProvider);
  final membershipsAsync = ref.watch(accountMembershipsProvider);
  if (profileAsync.isLoading || membershipsAsync.isLoading) {
    return const AsyncLoading();
  }
  if (profileAsync.hasError) {
    return AsyncError(profileAsync.error!, profileAsync.stackTrace!);
  }
  if (membershipsAsync.hasError) {
    return AsyncError(membershipsAsync.error!, membershipsAsync.stackTrace!);
  }
  final orgId = ref.watch(mophHospitalOrgIdProvider);
  if (orgId == null) {
    return AsyncError(
      StateError(
        'Your account is not authorized for hospital coordination. '
        'Operational MOPH staff need the coordination.hospital capability.',
      ),
      StackTrace.current,
    );
  }
  return AsyncData(orgId);
});

final barangayCaseOrgIdProvider = Provider<String?>((ref) {
  final profile = ref.watch(userProfileProvider).value;
  final memberships = ref.watch(accountMembershipsProvider).value ?? [];
  return OrgContextResolver.barangayOrgForCases(profile, memberships);
});

final barangayCaseOrgPresentationProvider =
    Provider<AsyncValue<BarangayOrganizationPresentation>>((ref) {
  final orgId = ref.watch(barangayCaseOrgIdProvider);
  if (orgId == null) {
    return AsyncError(
      StateError(
        'Your account is not authorized to manage cases for a Barangay organization. '
        'Check organization membership and case.read capability.',
      ),
      StackTrace.current,
    );
  }
  return ref.watch(cacheFirstOrganizationDirectoryPresentationProvider(orgId));
});

final barangayReportOrgPresentationProvider =
    Provider<AsyncValue<BarangayOrganizationPresentation>>((ref) {
  final orgId = ref.watch(barangayReportOrgIdProvider);
  if (orgId == null) {
    return AsyncError(
      StateError(
        'Your account is not authorized to submit reports for a Barangay organization. '
        'Check organization membership and report.submit capability.',
      ),
      StackTrace.current,
    );
  }
  return ref.watch(cacheFirstOrganizationDirectoryPresentationProvider(orgId));
});

final barangayCanReadCasesProvider = Provider<bool>((ref) {
  return ref.watch(barangayCaseOrgIdProvider) != null;
});

final barangayCanWriteCasesProvider = Provider<bool>((ref) {
  final profile = ref.watch(userProfileProvider).value;
  final memberships = ref.watch(accountMembershipsProvider).value ?? [];
  return OrgContextResolver.barangayHasCapabilityOnCaseOrg(
    profile,
    memberships,
    OrgCapabilities.caseWrite,
  );
});

final barangayCanAccessAssistanceInboxProvider = Provider<bool>((ref) {
  return ref.watch(barangayAssistanceOrgIdProvider) != null;
});

final barangayCanSubmitReportsProvider = Provider<bool>((ref) {
  return ref.watch(barangayReportOrgIdProvider) != null;
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
