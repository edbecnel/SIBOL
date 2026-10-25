import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sibol_app/features/auth/domain/entities/auth_user.dart';
import 'package:sibol_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:sibol_app/features/org/domain/barangay_organization_presentation.dart';
import 'package:sibol_app/features/org/domain/entities/organization.dart';
import 'package:sibol_app/features/org/domain/entities/organization_directory_entry.dart';
import 'package:sibol_app/features/org/presentation/providers/org_context_providers.dart';
import 'package:sibol_app/features/org/presentation/providers/organization_directory_providers.dart';
import 'package:sibol_app/features/org/presentation/providers/organization_presentation_providers.dart';

import 'support/fake_organization_directory_repository.dart';
import 'support/fake_organization_presentation_cache_store.dart';

const _orgId = 'barangay03';
const _uid = 'barangay-user';
const _presentation = BarangayOrganizationPresentation(
  organizationName: 'Barangay 3 (Poblacion)',
  siteLabel: 'Barangay 3, Balingasag',
);

OrganizationDirectoryEntry _entry() {
  return OrganizationDirectoryEntry(
    orgId: _orgId,
    type: OrganizationType.barangay,
    name: _presentation.organizationName,
    status: OrganizationStatus.active,
    updatedAt: DateTime.utc(2026, 1, 1),
    geographicSiteLabel: _presentation.siteLabel,
  );
}

ProviderContainer _container({
  required FakeOrganizationDirectoryRepository repo,
  FakeOrganizationPresentationCacheStore? cache,
}) {
  final cacheStore = cache ?? FakeOrganizationPresentationCacheStore();
  return ProviderContainer(
    overrides: [
      authStateChangesProvider.overrideWith(
        (ref) => Stream.value(AuthUser(uid: _uid, email: 'b@example.com')),
      ),
      organizationDirectoryRepositoryProvider.overrideWithValue(repo),
      organizationPresentationCacheStoreProvider.overrideWithValue(cacheStore),
      barangayCaseOrgIdProvider.overrideWithValue(_orgId),
      barangayReportOrgIdProvider.overrideWithValue(_orgId),
    ],
  );
}

Future<AsyncValue<BarangayOrganizationPresentation>> _waitForPresentation(
  ProviderContainer container,
) async {
  final completer = Completer<AsyncValue<BarangayOrganizationPresentation>>();
  final sub = container.listen(
    cacheFirstOrganizationDirectoryPresentationProvider(_orgId),
    (previous, next) {
      if (next.isLoading) return;
      if (!completer.isCompleted) completer.complete(next);
    },
    fireImmediately: true,
  );
  final result = await completer.future.timeout(const Duration(seconds: 2));
  sub.close();
  return result;
}

void main() {
  test('barangay case presentation resolves from directory document', () async {
    final container = _container(
      repo: FakeOrganizationDirectoryRepository(entries: {_orgId: _entry()}),
    );
    await _waitForPresentation(container);
    final asyncValue = container.read(barangayCaseOrgPresentationProvider);
    expect(asyncValue.hasValue, isTrue);
    expect(asyncValue.value?.organizationName, _presentation.organizationName);
    expect(asyncValue.value?.siteLabel, _presentation.siteLabel);
    container.dispose();
  });

  test('barangay report presentation resolves from cached presentation offline',
      () async {
    final cache = FakeOrganizationPresentationCacheStore();
    await cache.save(
      accountUid: _uid,
      orgId: _orgId,
      presentation: _presentation,
    );
    final container = _container(
      cache: cache,
      repo: FakeOrganizationDirectoryRepository(
        entries: {},
        fetchError: Exception('permission-denied'),
        watchError: Exception('permission-denied'),
      ),
    );
    await _waitForPresentation(container);
    final asyncValue = container.read(barangayReportOrgPresentationProvider);
    expect(asyncValue.hasValue, isTrue);
    expect(asyncValue.value?.organizationName, _presentation.organizationName);
    expect(asyncValue.value?.siteLabel, _presentation.siteLabel);
    container.dispose();
  });

}
