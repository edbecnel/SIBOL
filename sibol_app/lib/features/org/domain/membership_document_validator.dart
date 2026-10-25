import 'package:sibol_app/features/org/data/models/organization_membership_model.dart';
import 'package:sibol_app/features/org/domain/entities/organization_membership.dart';
import 'package:sibol_app/features/org/domain/membership_id.dart';

/// Validates Firestore membership payloads against canonical doc id and caller identity.
class MembershipDocumentValidator {
  const MembershipDocumentValidator._();

  static OrganizationMembership? parseTrustedMembership({
    required String documentId,
    required Map<String, dynamic> data,
    required String expectedAccountUid,
    required String expectedOrgId,
  }) {
    if (documentId != MembershipId.forOrgAndAccount(expectedOrgId, expectedAccountUid)) {
      return null;
    }
    final model = OrganizationMembershipModel.fromFirestore(data);
    if (model.accountUid != expectedAccountUid || model.orgId != expectedOrgId) {
      return null;
    }
    if (model.membershipId != documentId) {
      return null;
    }
    try {
      return model.toEntity();
    } on FormatException {
      return null;
    }
  }
}
