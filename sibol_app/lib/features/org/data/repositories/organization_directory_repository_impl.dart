import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sibol_app/core/constants/firestore_paths.dart';
import 'package:sibol_app/features/org/data/models/organization_directory_entry_model.dart';
import 'package:sibol_app/features/org/domain/entities/organization_directory_entry.dart';
import 'package:sibol_app/features/org/domain/membership_id.dart';
import 'package:sibol_app/features/org/domain/repositories/organization_directory_repository.dart';

class OrganizationDirectoryRepositoryImpl implements OrganizationDirectoryRepository {
  OrganizationDirectoryRepositoryImpl(this._firestore);

  final FirebaseFirestore _firestore;

  @override
  Stream<OrganizationDirectoryEntry?> watchEntry(String orgId) {
    if (!MembershipId.isValidOrgId(orgId)) {
      return Stream.value(null);
    }
    return _firestore
        .collection(FirestorePaths.organizationDirectory)
        .doc(orgId)
        .snapshots()
        .map((snap) {
      if (!snap.exists || snap.data() == null) return null;
      return OrganizationDirectoryEntryModel.fromFirestore(snap.data()!).toEntity();
    });
  }

  @override
  Future<OrganizationDirectoryEntry?> fetchEntry(String orgId) async {
    if (!MembershipId.isValidOrgId(orgId)) return null;
    final snap = await _firestore
        .collection(FirestorePaths.organizationDirectory)
        .doc(orgId)
        .get();
    return _entryFromSnapshot(snap);
  }

  @override
  Future<OrganizationDirectoryEntry?> fetchEntryPreferCache(String orgId) async {
    if (!MembershipId.isValidOrgId(orgId)) return null;
    try {
      final snap = await _firestore
          .collection(FirestorePaths.organizationDirectory)
          .doc(orgId)
          .get(const GetOptions(source: Source.cache));
      return _entryFromSnapshot(snap);
    } on FirebaseException {
      return null;
    }
  }

  OrganizationDirectoryEntry? _entryFromSnapshot(
    DocumentSnapshot<Map<String, dynamic>> snap,
  ) {
    if (!snap.exists || snap.data() == null) return null;
    return OrganizationDirectoryEntryModel.fromFirestore(snap.data()!).toEntity();
  }
}
