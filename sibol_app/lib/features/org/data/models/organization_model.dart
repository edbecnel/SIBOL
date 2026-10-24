import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sibol_app/features/org/domain/entities/organization.dart';

class OrganizationModel {
  OrganizationModel({
    required this.orgId,
    required this.type,
    required this.name,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.legacyBarangayLabel,
  });

  final String orgId;
  final String type;
  final String name;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? legacyBarangayLabel;

  factory OrganizationModel.fromFirestore(Map<String, dynamic> data) {
    return OrganizationModel(
      orgId: data['orgId'] as String? ?? '',
      type: data['type'] as String? ?? '',
      name: data['name'] as String? ?? '',
      status: data['status'] as String? ?? '',
      createdAt: _toDate(data['createdAt']),
      updatedAt: _toDate(data['updatedAt']),
      legacyBarangayLabel: data['legacyBarangayLabel'] as String?,
    );
  }

  Organization toEntity() {
    final parsedType = OrganizationType.fromFirestore(type);
    final parsedStatus = OrganizationStatus.fromFirestore(status);
    if (parsedType == null || parsedStatus == null) {
      throw FormatException('Invalid organization document: $orgId');
    }
    return Organization(
      orgId: orgId,
      type: parsedType,
      name: name,
      status: parsedStatus,
      createdAt: createdAt,
      updatedAt: updatedAt,
      legacyBarangayLabel: legacyBarangayLabel,
    );
  }

  static DateTime _toDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    throw FormatException('Expected timestamp');
  }
}
