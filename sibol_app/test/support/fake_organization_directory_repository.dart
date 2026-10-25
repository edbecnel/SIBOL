import 'dart:async';

import 'package:sibol_app/features/org/domain/entities/organization_directory_entry.dart';
import 'package:sibol_app/features/org/domain/repositories/organization_directory_repository.dart';

class FakeOrganizationDirectoryRepository
    implements OrganizationDirectoryRepository {
  FakeOrganizationDirectoryRepository({
    this.entries = const {},
    this.fetchError,
    this.watchError,
  });

  final Map<String, OrganizationDirectoryEntry?> entries;
  final Object? fetchError;
  final Object? watchError;

  @override
  Stream<OrganizationDirectoryEntry?> watchEntry(String orgId) {
    if (watchError != null) {
      return Stream<OrganizationDirectoryEntry?>.error(watchError!);
    }
    final entry = entries[orgId];
    return Stream<OrganizationDirectoryEntry?>.value(entry);
  }

  @override
  Future<OrganizationDirectoryEntry?> fetchEntry(String orgId) async {
    if (fetchError != null) throw fetchError!;
    return entries[orgId];
  }

  @override
  Future<OrganizationDirectoryEntry?> fetchEntryPreferCache(String orgId) async {
    return entries[orgId];
  }
}
