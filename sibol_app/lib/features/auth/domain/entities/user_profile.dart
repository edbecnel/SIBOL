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
    this.isCentralAdmin = false,
    this.onboardingStatus,
    this.mustChangePassword = false,
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

  /// Server-controlled; not client-writable (see Firestore rules).
  final bool isCentralAdmin;

  /// Server-controlled teen onboarding gate (`complete`, `pending_email_verification`, …).
  final String? onboardingStatus;

  /// Server-controlled; requires password change before operational use.
  final bool mustChangePassword;

  bool get teenAssistanceAllowed {
    if (role != SibolRole.teen) return true;
    if (selectedBarangayOrgId == null || selectedBarangayOrgId!.isEmpty) {
      return false;
    }
    if (onboardingStatus == 'pending_email_verification') return false;
    return active;
  }

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
        isCentralAdmin,
        onboardingStatus,
        mustChangePassword,
      ];
}
