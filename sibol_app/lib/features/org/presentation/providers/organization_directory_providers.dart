import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sibol_app/core/providers/firebase_providers.dart';
import 'package:sibol_app/features/org/data/repositories/organization_directory_repository_impl.dart';
import 'package:sibol_app/features/org/domain/barangay_organization_presentation.dart';
import 'package:sibol_app/features/org/domain/entities/organization_directory_entry.dart';
import 'package:sibol_app/features/org/domain/organization_directory_presentation_resolver.dart';
import 'package:sibol_app/features/org/domain/organization_presentation_unavailable.dart';
import 'package:sibol_app/features/org/domain/repositories/organization_directory_repository.dart';

final organizationDirectoryRepositoryProvider =
    Provider<OrganizationDirectoryRepository>((ref) {
  return OrganizationDirectoryRepositoryImpl(ref.watch(firestoreProvider));
});

/// Canonical organization display name (directory `name` only).
final organizationDirectoryNameProvider =
    Provider.family<AsyncValue<String>, String>((ref, orgId) {
  final entryAsync = ref.watch(organizationDirectoryEntryProvider(orgId));
  return entryAsync.when(
    loading: () => const AsyncLoading(),
    error: (e, st) => AsyncError(e, st),
    data: (entry) {
      final name = entry?.name.trim();
      if (name == null || name.isEmpty) {
        return AsyncError(
          StateError('Organization name for $orgId is unavailable.'),
          StackTrace.current,
        );
      }
      return AsyncData(name);
    },
  );
});

final organizationDirectoryEntryProvider =
    StreamProvider.family<OrganizationDirectoryEntry?, String>((ref, orgId) {
  final trimmed = orgId.trim();
  if (trimmed.isEmpty) {
    return Stream<OrganizationDirectoryEntry?>.value(null);
  }
  return ref.watch(organizationDirectoryRepositoryProvider).watchEntry(trimmed);
});

/// Canonical organization name and case/report site label from directory.
final organizationDirectoryPresentationProvider =
    Provider.family<AsyncValue<BarangayOrganizationPresentation>, String>(
        (ref, orgId) {
  final entryAsync = ref.watch(organizationDirectoryEntryProvider(orgId));
  return entryAsync.when(
    loading: () => const AsyncLoading(),
    error: (e, st) => AsyncError(e, st),
    data: (entry) {
      final presentation =
          OrganizationDirectoryPresentationResolver.presentationFromDirectoryEntry(
        entry,
      );
      if (presentation == null) {
        return AsyncError(
          OrganizationPresentationUnavailable(
            entry == null
                ? 'Organization directory entry for $orgId is unavailable. '
                    'Reconnect when online or ask an administrator to verify the directory.'
                : 'Organization $orgId is missing a valid name or geographic site label in the directory.',
          ),
          StackTrace.current,
        );
      }
      return AsyncData(presentation);
    },
  );
});
