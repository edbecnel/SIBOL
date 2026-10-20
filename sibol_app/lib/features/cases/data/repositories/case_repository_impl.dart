import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sibol_app/core/constants/firestore_paths.dart';
import 'package:sibol_app/features/cases/data/models/case_record_model.dart';
import 'package:sibol_app/features/cases/data/models/follow_up_model.dart';
import 'package:sibol_app/features/cases/domain/entities/case_record.dart';
import 'package:sibol_app/features/cases/domain/entities/follow_up.dart';
import 'package:sibol_app/features/cases/domain/repositories/case_repository.dart';

class CaseRepositoryImpl implements CaseRepository {
  CaseRepositoryImpl(this._firestore);

  final FirebaseFirestore _firestore;

  @override
  Stream<List<CaseRecord>> watchCases() {
    return _firestore
        .collection(FirestorePaths.cases)
        .orderBy('registeredAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => CaseRecordModel.fromFirestore(d.id, d.data()).toEntity())
            .toList());
  }

  @override
  Future<List<CaseRecord>> fetchCases() async {
    final snap = await _firestore
        .collection(FirestorePaths.cases)
        .orderBy('registeredAt', descending: true)
        .get();
    return snap.docs
        .map((d) => CaseRecordModel.fromFirestore(d.id, d.data()).toEntity())
        .toList();
  }

  @override
  Stream<List<FollowUp>> watchFollowUps(String caseId) {
    return _firestore
        .collection(FirestorePaths.cases)
        .doc(caseId)
        .collection(FirestorePaths.followUps)
        .orderBy('scheduledAt')
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => FollowUpModel.fromFirestore(d.id, d.data()).toEntity())
            .toList());
  }
}
