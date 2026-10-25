import 'package:flutter_test/flutter_test.dart';
import 'package:sibol_app/features/org/domain/entities/organization_membership.dart';
import 'package:sibol_app/features/org/domain/membership_document_validator.dart';
import 'package:sibol_app/features/org/domain/membership_id.dart';

void main() {
  const orgId = 'barangay03';
  const uid = 'WZj7Seh3qNUlGfnDaYbL1RBA4bNV';
  final docId = MembershipId.forOrgAndAccount(orgId, uid);
  final now = DateTime(2026, 1, 1);

  Map<String, dynamic> validData() => {
        'membershipId': docId,
        'orgId': orgId,
        'accountUid': uid,
        'status': 'active',
        'capabilities': ['org.manage_members'],
        'createdAt': now,
        'updatedAt': now,
      };

  test('accepts trusted canonical membership', () {
    final m = MembershipDocumentValidator.parseTrustedMembership(
      documentId: docId,
      data: validData(),
      expectedAccountUid: uid,
      expectedOrgId: orgId,
    );
    expect(m, isNotNull);
    expect(m!.status, MembershipStatus.active);
    expect(m.hasCapability('org.manage_members'), isTrue);
  });

  test('rejects doc id mismatch', () {
    final m = MembershipDocumentValidator.parseTrustedMembership(
      documentId: 'mbr_wrong__$uid',
      data: validData(),
      expectedAccountUid: uid,
      expectedOrgId: orgId,
    );
    expect(m, isNull);
  });

  test('rejects accountUid field mismatch', () {
    final data = validData();
    data['accountUid'] = 'otherUid123456789012345678';
    final m = MembershipDocumentValidator.parseTrustedMembership(
      documentId: docId,
      data: data,
      expectedAccountUid: uid,
      expectedOrgId: orgId,
    );
    expect(m, isNull);
  });
}
