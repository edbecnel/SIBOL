import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sibol_app/core/constants/firestore_paths.dart';
import 'package:sibol_app/features/org/data/models/organization_membership_model.dart';
import 'package:sibol_app/features/org/data/models/organization_model.dart';
import 'package:sibol_app/features/org/domain/entities/organization.dart';
import 'package:sibol_app/features/org/domain/entities/organization_membership.dart';
import 'package:sibol_app/features/org/domain/membership_document_validator.dart';
import 'package:sibol_app/features/org/domain/membership_id.dart';
import 'package:sibol_app/features/org/domain/repositories/organization_repository.dart';

class OrganizationRepositoryImpl implements OrganizationRepository {
  OrganizationRepositoryImpl(this._firestore);

  final FirebaseFirestore _firestore;

  @override
  Stream<Organization?> watchOrganization(String orgId) {
    return _firestore
        .collection(FirestorePaths.organizations)
        .doc(orgId)
        .snapshots()
        .map((snap) {
      if (!snap.exists || snap.data() == null) return null;
      return OrganizationModel.fromFirestore(snap.data()!).toEntity();
    });
  }

  @override
  Future<Organization?> fetchOrganization(String orgId) async {
    final snap =
        await _firestore.collection(FirestorePaths.organizations).doc(orgId).get();
    if (!snap.exists || snap.data() == null) return null;
    return OrganizationModel.fromFirestore(snap.data()!).toEntity();
  }

  @override
  Stream<List<OrganizationMembership>> watchMembershipForOrg({
    required String orgId,
    required String accountUid,
  }) {
    if (!MembershipId.isValidOrgId(orgId) || !MembershipId.isValidAccountUid(accountUid)) {
      return Stream.value(const []);
    }
    final docId = MembershipId.forOrgAndAccount(orgId, accountUid);
    return _firestore
        .collection(FirestorePaths.organizationMemberships)
        .doc(docId)
        .snapshots()
        .map((snap) {
      if (!snap.exists || snap.data() == null) {
        return const <OrganizationMembership>[];
      }
      final membership = MembershipDocumentValidator.parseTrustedMembership(
        documentId: snap.id,
        data: snap.data()!,
        expectedAccountUid: accountUid,
        expectedOrgId: orgId,
      );
      return membership == null ? const <OrganizationMembership>[] : [membership];
    });
  }

  @override
  Future<OrganizationMembership?> fetchMembership(String membershipId) async {
    final snap = await _firestore
        .collection(FirestorePaths.organizationMemberships)
        .doc(membershipId)
        .get();
    if (!snap.exists || snap.data() == null) return null;
    return OrganizationMembershipModel.fromFirestore(snap.data()!).toEntity();
  }
}
