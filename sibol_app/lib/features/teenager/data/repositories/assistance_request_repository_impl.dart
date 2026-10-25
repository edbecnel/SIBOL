import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:sibol_app/core/constants/firestore_paths.dart';
import 'package:sibol_app/core/domain/firestore_list_snapshot.dart';
import 'package:sibol_app/features/teenager/data/models/assistance_request_model.dart';
import 'package:sibol_app/features/teenager/domain/entities/assistance_request.dart';
import 'package:sibol_app/features/teenager/domain/repositories/assistance_request_repository.dart';

class AssistanceRequestRepositoryImpl implements AssistanceRequestRepository {
  AssistanceRequestRepositoryImpl(this._firestore, this._functions);

  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection(FirestorePaths.teenAssistanceRequests);

  @override
  Stream<FirestoreListSnapshot<AssistanceRequest>> watchMyRequests(
    String teenUid,
  ) {
    return _collection
        .where('teenUid', isEqualTo: teenUid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snap) => FirestoreListSnapshot(
            isFromCache: snap.metadata.isFromCache,
            hasPendingWrites: snap.metadata.hasPendingWrites,
            items: snap.docs
                .map(
                  (d) => AssistanceRequestModel.fromFirestore(d.id, d.data())
                      .toEntity(),
                )
                .toList(),
          ),
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
  Stream<FirestoreListSnapshot<AssistanceRequest>> watchIncomingForOrg(
    String orgId,
  ) {
    return _collection
        .where('orgId', isEqualTo: orgId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snap) => FirestoreListSnapshot(
            isFromCache: snap.metadata.isFromCache,
            hasPendingWrites: snap.metadata.hasPendingWrites,
            items: snap.docs
                .map(
                  (d) => AssistanceRequestModel.fromFirestore(d.id, d.data())
                      .toEntity(),
                )
                .toList(),
          ),
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
    required String idempotencyKey,
  }) async {
    await _functions.httpsCallable('regAcknowledgeTeenAssistanceRequest').call({
      'idempotencyKey': idempotencyKey,
      'requestId': requestId,
      'orgId': orgId,
    });
  }
}
