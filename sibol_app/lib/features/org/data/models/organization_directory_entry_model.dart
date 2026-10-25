import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sibol_app/features/org/domain/entities/organization.dart';
import 'package:sibol_app/features/org/domain/entities/organization_directory_entry.dart';

class OrganizationDirectoryEntryModel {
  OrganizationDirectoryEntryModel({
    required this.orgId,
    required this.name,
    required this.type,
    required this.status,
    required this.updatedAt,
    this.geographicSiteLabel,
  });

  final String orgId;
  final String name;
  final String type;
  final String status;
  final DateTime updatedAt;
  final String? geographicSiteLabel;

  factory OrganizationDirectoryEntryModel.fromFirestore(
    Map<String, dynamic> data,
  ) {
    return OrganizationDirectoryEntryModel(
      orgId: data['orgId'] as String? ?? '',
      name: data['name'] as String? ?? '',
      type: data['type'] as String? ?? '',
      status: data['status'] as String? ?? '',
      updatedAt: _toDate(data['updatedAt']),
      geographicSiteLabel: data['geographicSiteLabel'] as String?,
    );
  }

  OrganizationDirectoryEntry? toEntity() {
    final parsedType = OrganizationType.fromFirestore(type);
    final parsedStatus = OrganizationStatus.fromFirestore(status);
    if (parsedType == null || parsedStatus == null || orgId.isEmpty || name.isEmpty) {
      return null;
    }
    final site = geographicSiteLabel?.trim();
    return OrganizationDirectoryEntry(
      orgId: orgId,
      name: name,
      type: parsedType,
      status: parsedStatus,
      updatedAt: updatedAt,
      geographicSiteLabel: site != null && site.isNotEmpty ? site : null,
    );
  }

  static DateTime _toDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    throw FormatException('Expected timestamp');
  }
}
