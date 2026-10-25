import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sibol_app/core/constants/firestore_paths.dart';
import 'package:sibol_app/core/domain/firestore_document_snapshot.dart';
import 'package:sibol_app/core/domain/firestore_list_snapshot.dart';
import 'package:sibol_app/features/cases/data/models/case_record_model.dart';
import 'package:sibol_app/features/cases/data/models/follow_up_model.dart';
import 'package:sibol_app/features/cases/domain/entities/case_record.dart';
import 'package:sibol_app/features/cases/domain/entities/follow_up.dart';
import 'package:sibol_app/features/cases/domain/entities/follow_up_timeline_entry.dart';
import 'package:sibol_app/features/cases/domain/follow_up_sync_state.dart';
import 'package:sibol_app/features/cases/domain/follow_up_validation.dart';
import 'package:sibol_app/features/cases/domain/case_write_policy.dart';
import 'package:sibol_app/features/cases/domain/repositories/case_repository.dart';

class CaseRepositoryImpl implements CaseRepository {
  CaseRepositoryImpl(this._firestore);

  final FirebaseFirestore _firestore;

  @override
  Stream<FirestoreListSnapshot<CaseRecord>> watchCasesForOrg(String orgId) {
    return _firestore
        .collection(FirestorePaths.cases)
        .where('orgId', isEqualTo: orgId)
        .orderBy('registeredAt', descending: true)
        .snapshots()
        .map(
          (snap) => FirestoreListSnapshot(
            isFromCache: snap.metadata.isFromCache,
            hasPendingWrites: snap.metadata.hasPendingWrites,
            items: snap.docs
                .map(
                  (d) =>
                      CaseRecordModel.fromFirestore(d.id, d.data()).toEntity(),
                )
                .toList(),
          ),
        );
  }

  @override
  Future<List<CaseRecord>> fetchCasesForOrg(String orgId) async {
    final snap = await _firestore
        .collection(FirestorePaths.cases)
        .where('orgId', isEqualTo: orgId)
        .orderBy('registeredAt', descending: true)
        .get();
    return snap.docs
        .map((d) => CaseRecordModel.fromFirestore(d.id, d.data()).toEntity())
        .toList();
  }

  @override
  Stream<FirestoreDocumentSnapshot<CaseRecord>> watchCase(String caseId) {
    return _firestore
        .collection(FirestorePaths.cases)
        .doc(caseId)
        .snapshots()
        .map((snap) {
      CaseRecord? record;
      if (snap.exists) {
        final data = snap.data();
        if (data != null) {
          record = CaseRecordModel.fromFirestore(snap.id, data).toEntity();
        }
      }
      return FirestoreDocumentSnapshot(
        data: record,
        isFromCache: snap.metadata.isFromCache,
        hasPendingWrites: snap.metadata.hasPendingWrites,
      );
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
    final existingSnap = await ref.get(const GetOptions(source: Source.serverAndCache));
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
  Stream<List<FollowUpTimelineEntry>> watchFollowUps(String caseId) {
    // Chronological timeline: earliest scheduledAt first.
    return _firestore
        .collection(FirestorePaths.cases)
        .doc(caseId)
        .collection(FirestorePaths.followUps)
        .orderBy('scheduledAt')
        .snapshots()
        .map(
          (snap) => snap.docs.map((d) {
            final data = d.data();
            final followUp =
                FollowUpModel.fromFirestore(d.id, data).toEntity();
            final createdAtPresent = data['createdAt'] != null;
            final awaiting = FollowUpSyncState.awaitingServerConfirmation(
              hasPendingWrites: d.metadata.hasPendingWrites,
              createdAtPresentInDocument: createdAtPresent,
              createdByUid: data['createdByUid'] as String?,
            );
            return FollowUpTimelineEntry(
              followUp: followUp,
              isFromCache: d.metadata.isFromCache,
              hasPendingWrites: d.metadata.hasPendingWrites,
              awaitingServerConfirmation: awaiting,
            );
          }).toList(),
        );
  }

  @override
  Future<String> createFollowUp({
    required FollowUp followUp,
    required String createdByUid,
  }) async {
    if (createdByUid.isEmpty) {
      throw FormatException('Staff identity is required to record a follow-up.');
    }
    final notesError = FollowUpValidation.validateNotes(followUp.notes);
    if (notesError != null) {
      throw FormatException(notesError);
    }
    if (followUp.caseId.isEmpty) {
      throw FormatException('Follow-up is missing caseId.');
    }
    final caseRef = _firestore.collection(FirestorePaths.cases).doc(followUp.caseId);
    final caseSnap = await caseRef.get(const GetOptions(source: Source.serverAndCache));
    if (!caseSnap.exists) {
      throw StateError('Case not found.');
    }
    final ref = caseRef.collection(FirestorePaths.followUps).doc();
    final model = FollowUpModel.fromEntity(
      FollowUp(
        followUpId: ref.id,
        caseId: followUp.caseId,
        scheduledAt: followUp.scheduledAt,
        completedAt: followUp.completedAt,
        status: followUp.status,
        notes: followUp.notes,
      ),
    );
    await ref.set(model.toFirestoreCreate(createdByUid: createdByUid));
    return ref.id;
  }
}
