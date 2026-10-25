import 'package:sibol_app/features/org/domain/entities/organization_directory_entry.dart';

abstract class OrganizationDirectoryRepository {
  Stream<OrganizationDirectoryEntry?> watchEntry(String orgId);

  Future<OrganizationDirectoryEntry?> fetchEntry(String orgId);
}
