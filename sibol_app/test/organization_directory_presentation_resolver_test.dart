import 'package:flutter_test/flutter_test.dart';
import 'package:sibol_app/features/org/domain/barangay_organization_presentation.dart';
import 'package:sibol_app/features/org/domain/entities/organization.dart';
import 'package:sibol_app/features/org/domain/entities/organization_directory_entry.dart';
import 'package:sibol_app/features/org/domain/organization_directory_presentation_resolver.dart';
import 'package:sibol_app/features/org/domain/organization_presentation_unavailable.dart';

import 'support/fake_organization_directory_repository.dart';
import 'support/fake_organization_presentation_cache_store.dart';

const _orgId = 'barangay03';
const _uidA = 'user-a';
const _uidB = 'user-b';
const _presentation = BarangayOrganizationPresentation(
  organizationName: 'Barangay 3 (Poblacion)',
  siteLabel: 'Barangay 3, Balingasag',
);

OrganizationDirectoryEntry _entry() {
  return OrganizationDirectoryEntry(
    orgId: _orgId,
    type: OrganizationType.barangay,
    name: 'Barangay 3 (Poblacion)',
    status: OrganizationStatus.active,
    updatedAt: DateTime.utc(2026, 1, 1),
    geographicSiteLabel: 'Barangay 3, Balingasag',
  );
}

void main() {
  test('presentationFromDirectoryEntry rejects missing site label', () {
    final invalid = OrganizationDirectoryEntry(
      orgId: _orgId,
      type: OrganizationType.barangay,
      name: 'Barangay 3 (Poblacion)',
      status: OrganizationStatus.active,
      updatedAt: DateTime.utc(2026, 1, 1),
    );
    expect(
      OrganizationDirectoryPresentationResolver.presentationFromDirectoryEntry(
        invalid,
      ),
      isNull,
    );
  });

  test('watchPresentation emits directory entry when online', () async {
    final cache = FakeOrganizationPresentationCacheStore();
    final repo = FakeOrganizationDirectoryRepository(entries: {_orgId: _entry()});
    final resolver = OrganizationDirectoryPresentationResolver(
      repository: repo,
      cache: cache,
    );

    final values = await resolver
        .watchPresentation(accountUid: _uidA, orgId: _orgId)
        .take(1)
        .toList();

    expect(values.single.organizationName, _presentation.organizationName);
    expect(values.single.siteLabel, _presentation.siteLabel);
    final cached = await cache.load(accountUid: _uidA, orgId: _orgId);
    expect(cached?.organizationName, _presentation.organizationName);
    expect(cached?.siteLabel, _presentation.siteLabel);
  });

  test('watchPresentation uses cached presentation when directory fetch fails',
      () async {
    final cache = FakeOrganizationPresentationCacheStore();
    await cache.save(
      accountUid: _uidA,
      orgId: _orgId,
      presentation: _presentation,
    );
    final repo = FakeOrganizationDirectoryRepository(
      entries: {},
      fetchError: Exception('permission-denied'),
      watchError: Exception('permission-denied'),
    );
    final resolver = OrganizationDirectoryPresentationResolver(
      repository: repo,
      cache: cache,
    );

    final values = await resolver
        .watchPresentation(accountUid: _uidA, orgId: _orgId)
        .take(1)
        .toList();

    expect(values.single.organizationName, _presentation.organizationName);
    expect(values.single.siteLabel, _presentation.siteLabel);
  });

  test('watchPresentation errors when directory missing and no trusted cache',
      () async {
    final cache = FakeOrganizationPresentationCacheStore();
    final repo = FakeOrganizationDirectoryRepository(
      entries: {_orgId: null},
      fetchError: Exception('permission-denied'),
    );
    final resolver = OrganizationDirectoryPresentationResolver(
      repository: repo,
      cache: cache,
    );

    await expectLater(
      resolver.watchPresentation(accountUid: _uidA, orgId: _orgId),
      emitsError(isA<OrganizationPresentationUnavailable>()),
    );
  });

  test('presentation cache is isolated per user', () async {
    final cache = FakeOrganizationPresentationCacheStore();
    await cache.save(
      accountUid: _uidA,
      orgId: _orgId,
      presentation: _presentation,
    );
    expect(
      await cache.load(accountUid: _uidB, orgId: _orgId),
      isNull,
    );
  });
}
