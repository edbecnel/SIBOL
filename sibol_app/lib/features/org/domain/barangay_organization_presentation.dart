import 'package:sibol_app/features/org/domain/entities/organization.dart';

/// Read-only labels derived from an authoritative barangay organization record.
class BarangayOrganizationPresentation {
  const BarangayOrganizationPresentation({
    required this.organizationName,
    required this.siteLabel,
  });

  /// Registry `name` (authoritative organization display).
  final String organizationName;

  /// Legacy routing / case `barangay` string (`legacyBarangayLabel` on the org).
  final String siteLabel;

  /// Resolves presentation from [org]. Returns null when the record cannot supply
  /// a geographic site label (no profile fallback).
  static BarangayOrganizationPresentation? fromOrganization(Organization? org) {
    if (org == null) return null;
    if (org.type != OrganizationType.barangay) return null;
    if (org.status != OrganizationStatus.active) return null;
    final name = org.name.trim();
    if (name.isEmpty) return null;
    final site = org.legacyBarangayLabel?.trim() ?? '';
    if (site.length < 2) return null;
    return BarangayOrganizationPresentation(
      organizationName: name,
      siteLabel: site,
    );
  }
}
