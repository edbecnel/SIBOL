import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sibol_app/core/constants/firestore_paths.dart';
import 'package:sibol_app/features/cases/data/models/case_record_model.dart';
import 'package:sibol_app/features/cases/data/models/follow_up_model.dart';
import 'package:sibol_app/features/cases/domain/entities/case_record.dart';
import 'package:sibol_app/features/cases/domain/entities/follow_up.dart';
import 'package:sibol_app/features/cases/domain/case_write_policy.dart';
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
  Stream<CaseRecord?> watchCase(String caseId) {
    return _firestore
        .collection(FirestorePaths.cases)
        .doc(caseId)
        .snapshots()
        .map((snap) {
      if (!snap.exists) return null;
      final data = snap.data();
      if (data == null) return null;
      return CaseRecordModel.fromFirestore(snap.id, data).toEntity();
    });
  }

  @override
  Future<String> createCase(CaseRecord record) async {
    final policyError = CaseWritePolicy.validateForCreate(record);
    if (policyError != null) {
      throw FormatException(policyError);
    }
    CaseRecordModel.assertValidForWrite(record);
    final ref = _firestore.collection(FirestorePaths.cases).doc();
    final model = CaseRecordModel.fromEntity(
      CaseRecord(
        caseId: ref.id,
        demoName: record.demoName,
        age: record.age,
        barangay: record.barangay,
        orgId: record.orgId,
        caseStatus: record.caseStatus,
        registeredAt: record.registeredAt,
        nextFollowUpAt: record.nextFollowUpAt,
        notes: record.notes,
        createdAt: record.createdAt,
        updatedAt: record.updatedAt,
        reportStatus: record.reportStatus,
      ),
    );
    await ref.set(model.toFirestoreCreate());
    return ref.id;
  }

  @override
  Future<void> updateCase(CaseRecord record) async {
    final ref = _firestore.collection(FirestorePaths.cases).doc(record.caseId);
    final existingSnap = await ref.get();
    if (!existingSnap.exists || existingSnap.data() == null) {
      throw StateError('Case not found.');
    }
    final existing =
        CaseRecordModel.fromFirestore(record.caseId, existingSnap.data()!)
            .toEntity();
    final policyError = CaseWritePolicy.validateForUpdate(
      updated: record,
      existing: existing,
    );
    if (policyError != null) {
      throw FormatException(policyError);
    }
    CaseRecordModel.assertValidForWrite(record);
    final model = CaseRecordModel.fromEntity(record);
    await ref.update(model.toFirestoreUpdate(createdAt: existing.createdAt));
  }

  @override
  Stream<List<FollowUp>> watchFollowUps(String caseId) {
    // Chronological timeline: earliest scheduledAt first.
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
