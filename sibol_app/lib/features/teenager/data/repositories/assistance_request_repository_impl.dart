import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sibol_app/core/constants/firestore_paths.dart';
import 'package:sibol_app/features/teenager/data/models/assistance_request_model.dart';
import 'package:sibol_app/features/teenager/domain/assistance_request_status.dart';
import 'package:sibol_app/features/teenager/domain/entities/assistance_request.dart';
import 'package:sibol_app/features/teenager/domain/repositories/assistance_request_repository.dart';

class AssistanceRequestRepositoryImpl implements AssistanceRequestRepository {
  AssistanceRequestRepositoryImpl(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection(FirestorePaths.teenAssistanceRequests);

  @override
  Stream<List<AssistanceRequest>> watchMyRequests(String teenUid) {
    return _collection
        .where('teenUid', isEqualTo: teenUid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map(
                (d) =>
                    AssistanceRequestModel.fromFirestore(d.id, d.data()).toEntity(),
              )
              .toList(),
        );
  }

  @override
  Stream<AssistanceRequest?> watchRequest(String requestId, String teenUid) {
    return _collection.doc(requestId).snapshots().map((snap) {
      if (!snap.exists) return null;
      final data = snap.data();
      if (data == null) return null;
      final model = AssistanceRequestModel.fromFirestore(snap.id, data);
      if (model.teenUid != teenUid) return null;
      return model.toEntity();
    });
  }

  @override
  Stream<List<AssistanceRequest>> watchIncomingForOrg(String orgId) {
    return _collection
        .where('orgId', isEqualTo: orgId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map(
                (d) =>
                    AssistanceRequestModel.fromFirestore(d.id, d.data()).toEntity(),
              )
              .toList(),
        );
  }

  @override
  Stream<AssistanceRequest?> watchRequestForOrg(
    String requestId,
    String orgId,
  ) {
    return _collection.doc(requestId).snapshots().map((snap) {
      if (!snap.exists) return null;
      final data = snap.data();
      if (data == null) return null;
      final model = AssistanceRequestModel.fromFirestore(snap.id, data);
      if (model.orgId != orgId) return null;
      return model.toEntity();
    });
  }

  @override
  Future<void> acknowledgeRequest({
    required String requestId,
    required String orgId,
    required String barangayStaffUid,
  }) async {
    final ref = _collection.doc(requestId);
    await _firestore.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) {
        throw StateError('Request not found.');
      }
      final data = snap.data()!;
      if (data['orgId'] != orgId) {
        throw StateError('Request is not assigned to your organization.');
      }
      if (data['status'] != AssistanceRequestStatus.submitted.firestoreValue) {
        throw StateError('Request has already been acknowledged.');
      }
      tx.update(ref, {
        'status': AssistanceRequestStatus.acknowledged.firestoreValue,
        'acknowledgedAt': FieldValue.serverTimestamp(),
        'acknowledgedByUid': barangayStaffUid,
      });
    });
  }
}
