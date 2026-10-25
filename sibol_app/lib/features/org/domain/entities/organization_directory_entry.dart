import 'package:equatable/equatable.dart';
import 'package:sibol_app/features/org/domain/entities/organization.dart';

class OrganizationDirectoryEntry extends Equatable {
  const OrganizationDirectoryEntry({
    required this.orgId,
    required this.name,
    required this.type,
    required this.status,
    required this.updatedAt,
    this.geographicSiteLabel,
  });

  final String orgId;
  final String name;
  final OrganizationType type;
  final OrganizationStatus status;
  final DateTime updatedAt;
  final String? geographicSiteLabel;

  @override
  List<Object?> get props =>
      [orgId, name, type, status, updatedAt, geographicSiteLabel];
}
