import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sibol_app/core/permissions/sibol_role.dart';
import 'package:sibol_app/features/auth/domain/entities/user_profile.dart';

class UserProfileModel {
  UserProfileModel({
    required this.uid,
    required this.role,
    required this.displayName,
    required this.active,
    required this.createdAt,
    this.assignedBarangay,
    this.primaryOrgId,
    this.selectedBarangayOrgId,
    this.isCentralAdmin = false,
    this.onboardingStatus,
  });

  final String uid;
  final String role;
  final String displayName;
  final bool active;
  final DateTime createdAt;
  final String? assignedBarangay;
  final String? primaryOrgId;
  final String? selectedBarangayOrgId;
  final bool isCentralAdmin;
  final String? onboardingStatus;

  factory UserProfileModel.fromFirestore(String uid, Map<String, dynamic> data) {
    final created = data['createdAt'];
    return UserProfileModel(
      uid: uid,
      role: data['role'] as String? ?? '',
      displayName: data['displayName'] as String? ?? '',
      active: data['active'] as bool? ?? false,
      createdAt: created is Timestamp ? created.toDate() : DateTime.now(),
      assignedBarangay: data['assignedBarangay'] as String?,
      primaryOrgId: data['primaryOrgId'] as String?,
      selectedBarangayOrgId: data['selectedBarangayOrgId'] as String?,
      isCentralAdmin: data['isCentralAdmin'] as bool? ?? false,
      onboardingStatus: data['onboardingStatus'] as String?,
    );
  }

  UserProfile toEntity() {
    final parsedRole = SibolRole.fromFirestore(role);
    if (parsedRole == null) {
      throw FormatException('Invalid role on user profile: $role');
    }
    return UserProfile(
      uid: uid,
      role: parsedRole,
      displayName: displayName,
      active: active,
      createdAt: createdAt,
      assignedBarangay: assignedBarangay,
      primaryOrgId: primaryOrgId,
      selectedBarangayOrgId: selectedBarangayOrgId,
      isCentralAdmin: isCentralAdmin,
      onboardingStatus: onboardingStatus,
    );
  }
}
