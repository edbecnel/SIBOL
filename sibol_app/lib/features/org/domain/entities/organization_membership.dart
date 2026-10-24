import 'package:equatable/equatable.dart';

enum MembershipStatus {
  invited('invited'),
  pending('pending'),
  active('active'),
  rejected('rejected'),
  suspended('suspended'),
  revoked('revoked');

  const MembershipStatus(this.firestoreValue);
  final String firestoreValue;

  static MembershipStatus? fromFirestore(String? value) {
    if (value == null) return null;
    for (final s in MembershipStatus.values) {
      if (s.firestoreValue == value) return s;
    }
    return null;
  }
}

class OrganizationMembership extends Equatable {
  const OrganizationMembership({
    required this.membershipId,
    required this.orgId,
    required this.accountUid,
    required this.status,
    required this.capabilities,
    required this.createdAt,
    required this.updatedAt,
  });

  final String membershipId;
  final String orgId;
  final String accountUid;
  final MembershipStatus status;
  final List<String> capabilities;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool hasCapability(String capability) => capabilities.contains(capability);

  @override
  List<Object?> get props =>
      [membershipId, orgId, accountUid, status, capabilities, createdAt, updatedAt];
}
