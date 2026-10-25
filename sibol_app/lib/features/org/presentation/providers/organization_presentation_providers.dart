import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:sibol_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:sibol_app/features/org/data/organization_presentation_cache_store.dart';
import 'package:sibol_app/features/org/domain/barangay_organization_presentation.dart';
import 'package:sibol_app/features/org/domain/organization_directory_presentation_resolver.dart';
import 'package:sibol_app/features/org/presentation/providers/organization_directory_providers.dart';

final organizationPresentationCacheStoreProvider =
    Provider<OrganizationPresentationCachePersistence>((ref) {
  return OrganizationPresentationCacheStore(const FlutterSecureStorage());
});

final organizationDirectoryPresentationResolverProvider =
    Provider<OrganizationDirectoryPresentationResolver>((ref) {
  return OrganizationDirectoryPresentationResolver(
    repository: ref.watch(organizationDirectoryRepositoryProvider),
    cache: ref.watch(organizationPresentationCacheStoreProvider),
  );
});

/// Cache-first directory presentation for offline-safe case/report forms.
final cacheFirstOrganizationDirectoryPresentationProvider =
    StreamProvider.family<BarangayOrganizationPresentation, String>(
        (ref, orgId) {
  final auth = ref.watch(authStateChangesProvider).value;
  final trimmedOrg = orgId.trim();
  if (trimmedOrg.isEmpty) {
    return Stream<BarangayOrganizationPresentation>.error(
      StateError('Organization id is required.'),
    );
  }
  final uid = auth?.uid.trim();
  if (uid == null || uid.isEmpty) {
    return Stream<BarangayOrganizationPresentation>.error(
      StateError('Sign in to load organization details.'),
    );
  }
  return ref
      .watch(organizationDirectoryPresentationResolverProvider)
      .watchPresentation(accountUid: uid, orgId: trimmedOrg);
});
