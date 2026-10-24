import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sibol_app/features/org/domain/entities/organization_membership.dart';

class OrganizationMembershipModel {
  OrganizationMembershipModel({
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
  final String status;
  final List<String> capabilities;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory OrganizationMembershipModel.fromFirestore(Map<String, dynamic> data) {
    final caps = data['capabilities'];
    return OrganizationMembershipModel(
      membershipId: data['membershipId'] as String? ?? '',
      orgId: data['orgId'] as String? ?? '',
      accountUid: data['accountUid'] as String? ?? '',
      status: data['status'] as String? ?? '',
      capabilities: caps is List ? caps.map((e) => e.toString()).toList() : [],
      createdAt: _toDate(data['createdAt']),
      updatedAt: _toDate(data['updatedAt']),
    );
  }

  OrganizationMembership toEntity() {
    final parsedStatus = MembershipStatus.fromFirestore(status);
    if (parsedStatus == null) {
      throw FormatException('Invalid membership status: $membershipId');
    }
    return OrganizationMembership(
      membershipId: membershipId,
      orgId: orgId,
      accountUid: accountUid,
      status: parsedStatus,
      capabilities: List<String>.from(capabilities),
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  static DateTime _toDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    throw FormatException('Expected timestamp');
  }
}
