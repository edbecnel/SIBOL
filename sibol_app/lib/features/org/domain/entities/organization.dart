import 'package:equatable/equatable.dart';

enum OrganizationType {
  barangay('barangay'),
  hospital('hospital');

  const OrganizationType(this.firestoreValue);
  final String firestoreValue;

  static OrganizationType? fromFirestore(String? value) {
    if (value == null) return null;
    for (final t in OrganizationType.values) {
      if (t.firestoreValue == value) return t;
    }
    return null;
  }
}

enum OrganizationStatus {
  pending('pending'),
  active('active'),
  suspended('suspended');

  const OrganizationStatus(this.firestoreValue);
  final String firestoreValue;

  static OrganizationStatus? fromFirestore(String? value) {
    if (value == null) return null;
    for (final s in OrganizationStatus.values) {
      if (s.firestoreValue == value) return s;
    }
    return null;
  }
}

class Organization extends Equatable {
  const Organization({
    required this.orgId,
    required this.type,
    required this.name,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.legacyBarangayLabel,
  });

  final String orgId;
  final OrganizationType type;
  final String name;
  final OrganizationStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? legacyBarangayLabel;

  @override
  List<Object?> get props =>
      [orgId, type, name, status, createdAt, updatedAt, legacyBarangayLabel];
}
