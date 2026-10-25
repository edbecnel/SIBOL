import 'dart:async';

import 'package:sibol_app/features/org/data/organization_presentation_cache_store.dart';
import 'package:sibol_app/features/org/domain/barangay_organization_presentation.dart';
import 'package:sibol_app/features/org/domain/entities/organization_directory_entry.dart';
import 'package:sibol_app/features/org/domain/organization_presentation_unavailable.dart';
import 'package:sibol_app/features/org/domain/repositories/organization_directory_repository.dart';

/// Resolves user-visible barangay organization labels from organizationDirectory,
/// with a trusted last-known cache for offline form initialization.
class OrganizationDirectoryPresentationResolver {
  OrganizationDirectoryPresentationResolver({
    required OrganizationDirectoryRepository repository,
    required OrganizationPresentationCachePersistence cache,
  })  : _repository = repository,
        _cache = cache;

  final OrganizationDirectoryRepository _repository;
  final OrganizationPresentationCachePersistence _cache;

  static BarangayOrganizationPresentation? presentationFromDirectoryEntry(
    OrganizationDirectoryEntry? entry,
  ) {
    if (entry == null) return null;
    final name = entry.name.trim();
    if (name.isEmpty) return null;
    final site = entry.geographicSiteLabel?.trim() ?? '';
    if (site.length < 2) return null;
    return BarangayOrganizationPresentation(
      organizationName: name,
      siteLabel: site,
    );
  }

  Stream<BarangayOrganizationPresentation> watchPresentation({
    required String accountUid,
    required String orgId,
  }) {
    final controller = StreamController<BarangayOrganizationPresentation>();
    StreamSubscription<OrganizationDirectoryEntry?>? directorySub;
    var closed = false;

    Future<void> emitFromEntry(OrganizationDirectoryEntry? entry) async {
      final presentation = presentationFromDirectoryEntry(entry);
      if (presentation == null) return;
      await _cache.save(
        accountUid: accountUid,
        orgId: orgId,
        presentation: presentation,
        directoryUpdatedAt: entry?.updatedAt,
      );
      if (!closed) controller.add(presentation);
    }

    Future<void> start() async {
      BarangayOrganizationPresentation? trustedCache;
      try {
        trustedCache = await _cache.load(
          accountUid: accountUid,
          orgId: orgId,
        );
        if (trustedCache != null && !closed) {
          controller.add(trustedCache);
        }
      } catch (_) {
        // Ignore secure-storage read failures; directory fetch may still succeed.
      }

      OrganizationDirectoryEntry? resolvedEntry;
      try {
        resolvedEntry = await _repository.fetchEntryPreferCache(orgId);
        if (resolvedEntry == null) {
          resolvedEntry = await _repository.fetchEntry(orgId);
        }
      } catch (_) {
        resolvedEntry = null;
      }

      if (resolvedEntry != null) {
        await emitFromEntry(resolvedEntry);
      } else if (trustedCache == null && !closed) {
        controller.addError(
          OrganizationPresentationUnavailable.missingTrustedCache(orgId),
        );
        await controller.close();
        return;
      }

      directorySub = _repository.watchEntry(orgId).listen(
        (entry) async {
          if (entry == null) return;
          await emitFromEntry(entry);
        },
        onError: (_) {
          // Keep showing trusted cache; do not surface raw Firestore errors.
        },
      );
    }

    unawaited(start().catchError((Object e, StackTrace st) {
      if (!closed) controller.addError(e, st);
    }));

    controller.onCancel = () async {
      closed = true;
      await directorySub?.cancel();
    };

    return controller.stream;
  }
}
