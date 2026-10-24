import 'package:equatable/equatable.dart';
import 'package:sibol_app/core/permissions/sibol_role.dart';

class UserProfile extends Equatable {
  const UserProfile({
    required this.uid,
    required this.role,
    required this.displayName,
    required this.active,
    required this.createdAt,
    this.assignedBarangay,
    this.primaryOrgId,
    this.selectedBarangayOrgId,
  });

  final String uid;
  final SibolRole role;
  final String displayName;
  final bool active;
  final DateTime createdAt;

  /// Provisioned demo site label; used for teen assistance routing (not client-writable).
  final String? assignedBarangay;

  /// Server/migration-set hospital or barangay org context (not client-writable).
  final String? primaryOrgId;

  /// Teen routing org for assistance (not client-writable).
  final String? selectedBarangayOrgId;

  @override
  List<Object?> get props => [
        uid,
        role,
        displayName,
        active,
        createdAt,
        assignedBarangay,
        primaryOrgId,
        selectedBarangayOrgId,
      ];
}
