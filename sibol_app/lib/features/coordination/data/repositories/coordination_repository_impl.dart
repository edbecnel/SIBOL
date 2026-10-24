import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:sibol_app/core/constants/firestore_paths.dart';
import 'package:sibol_app/features/coordination/data/models/coordination_staff_event_model.dart';
import 'package:sibol_app/features/coordination/data/models/coordination_thread_model.dart';
import 'package:sibol_app/features/coordination/domain/entities/coordination_staff_event.dart';
import 'package:sibol_app/features/coordination/domain/entities/coordination_thread.dart';
import 'package:sibol_app/features/coordination/data/coordination_registry_referral_probe.dart';
import 'package:sibol_app/features/coordination/domain/repositories/coordination_repository.dart';

class CoordinationRepositoryImpl implements CoordinationRepository {
  CoordinationRepositoryImpl(this._firestore, this._functions);

  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;

  static const _openPhases = ['referred', 'awaitingBarangay', 'awaitingMoph'];

  CollectionReference<Map<String, dynamic>> get _threads =>
      _firestore.collection(FirestorePaths.caseCoordinationThreads);

  @override
  Future<CreateCoordinationReferralResult> createCoordinationReferral({
    required String assistanceRequestId,
    required String barangayReferralSummary,
  }) async {
    final callable = _functions.httpsCallable('createCoordinationReferral');
    final result = await callable.call<Map<String, dynamic>>({
      'assistanceRequestId': assistanceRequestId,
      'barangayReferralSummary': barangayReferralSummary.trim(),
    });
    final data = result.data;
    return CreateCoordinationReferralResult(
      threadId: data['threadId'] as String,
      displayRef: data['displayRef'] as String,
    );
  }

  @override
  Stream<List<CoordinationThread>> watchOpenThreadsForMoph() {
    return _threads
        .where('phase', whereIn: _openPhases)
        .orderBy('lastStaffEventAt', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map(
                (d) => CoordinationThreadModel.fromFirestore(d.id, d.data())
                    .toEntity(),
              )
              .toList(),
        );
  }

  @override
  Stream<CoordinationThread?> watchThreadForMoph(String threadId) {
    return _threads.doc(threadId).snapshots().map((snap) {
      if (!snap.exists) return null;
      final data = snap.data();
      if (data == null) return null;
      return CoordinationThreadModel.fromFirestore(snap.id, data).toEntity();
    });
  }

  @override
  Stream<List<CoordinationStaffEvent>> watchStaffEventsForThread(
    String threadId,
  ) {
    return _threads
        .doc(threadId)
        .collection(FirestorePaths.caseCoordinationStaffEvents)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map(
                (d) => CoordinationStaffEventModel.fromFirestore(d.id, d.data())
                    .toEntity(),
              )
              .toList(),
        );
  }

  @override
  Stream<bool> watchReferralExistsForAssistanceRequest(
    String assistanceRequestId,
  ) {
    return mapRegistrySnapshotsToReferralExists(
      _firestore
          .collection(FirestorePaths.barangayCoordinationRegistry)
          .doc(assistanceRequestId)
          .snapshots(),
    );
  }
}
