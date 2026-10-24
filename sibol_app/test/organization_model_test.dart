import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sibol_app/features/org/data/models/organization_membership_model.dart';
import 'package:sibol_app/features/org/data/models/organization_model.dart';
import 'package:sibol_app/features/org/domain/entities/organization.dart';
import 'package:sibol_app/features/org/domain/entities/organization_membership.dart';

void main() {
  test('parses organization from firestore map', () {
    final now = Timestamp.fromDate(DateTime(2026, 10, 24));
    final entity = OrganizationModel.fromFirestore({
      'orgId': 'barangay03',
      'type': 'barangay',
      'name': 'Demo',
      'status': 'active',
      'createdAt': now,
      'updatedAt': now,
    }).toEntity();

    expect(entity.type, OrganizationType.barangay);
    expect(entity.status, OrganizationStatus.active);
  });

  test('parses membership capabilities', () {
    final now = Timestamp.fromDate(DateTime(2026, 10, 24));
    final entity = OrganizationMembershipModel.fromFirestore({
      'membershipId': 'mbr_barangay03__uid',
      'orgId': 'barangay03',
      'accountUid': 'uid',
      'status': 'active',
      'capabilities': ['case.read', 'org.manage_members'],
      'createdAt': now,
      'updatedAt': now,
    }).toEntity();

    expect(entity.status, MembershipStatus.active);
    expect(entity.hasCapability('case.read'), isTrue);
    expect(entity.hasCapability('case.write'), isFalse);
  });
}
