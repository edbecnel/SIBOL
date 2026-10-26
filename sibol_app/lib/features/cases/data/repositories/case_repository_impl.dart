import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sibol_app/core/constants/firestore_paths.dart';
import 'package:sibol_app/core/domain/firestore_document_snapshot.dart';
import 'package:sibol_app/core/domain/firestore_list_snapshot.dart';
import 'package:sibol_app/core/firestore/firestore_snapshot_listeners.dart';
import 'package:sibol_app/core/firestore/local_firestore_write.dart';
import 'package:sibol_app/features/cases/data/models/case_record_model.dart';
import 'package:sibol_app/features/cases/data/models/follow_up_model.dart';
import 'package:sibol_app/features/cases/domain/case_edit_record_resolver.dart';
import 'package:sibol_app/features/cases/domain/case_write_policy.dart';
import 'package:sibol_app/features/cases/domain/entities/case_list_entry.dart';
import 'package:sibol_app/features/cases/domain/entities/case_record.dart';
import 'package:sibol_app/features/cases/domain/entities/follow_up.dart';
import 'package:sibol_app/features/cases/domain/entities/follow_up_timeline_entry.dart';
import 'package:sibol_app/features/cases/domain/follow_up_sync_state.dart';
import 'package:sibol_app/features/cases/domain/follow_up_validation.dart';
import 'package:sibol_app/features/cases/domain/repositories/case_repository.dart';

class CaseRepositoryImpl implements CaseRepository {
  CaseRepositoryImpl(this._firestore);

  final FirebaseFirestore _firestore;

  @override
  String newCaseDocumentId() {
    return _firestore.collection(FirestorePaths.cases).doc().id;
  }

  @override
  Stream<FirestoreListSnapshot<CaseListEntry>> watchCasesForOrg(String orgId) {
    return _firestore
        .collection(FirestorePaths.cases)
        .where('orgId', isEqualTo: orgId)
        .orderBy('registeredAt', descending: true)
        .snapshotsWithCacheMetadata()
        .map(
          (snap) => FirestoreListSnapshot(
            isFromCache: snap.metadata.isFromCache,
            hasPendingWrites: snap.metadata.hasPendingWrites,
            items: snap.docs
                .map(
                  (d) => CaseListEntry(
                    record: CaseRecordModel.fromFirestore(d.id, d.data())
                        .toEntity(),
                    isFromCache: d.metadata.isFromCache,
                    hasPendingWrites: d.metadata.hasPendingWrites,
                  ),
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
        .snapshotsWithCacheMetadata()
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
  Future<CaseRecord?> fetchCasePreferCache(String caseId) async {
    return _readCaseFromCache(_caseRef(caseId));
  }

  @override
  Future<CaseRecord?> fetchCase(String caseId) async {
    final ref = _caseRef(caseId);
    try {
      final snap = await ref.get(const GetOptions(source: Source.serverAndCache));
      if (!snap.exists || snap.data() == null) return null;
      return CaseRecordModel.fromFirestore(ref.id, snap.data()!).toEntity();
    } on FirebaseException {
      return await fetchCasePreferCache(caseId);
    }
  }

  @override
  Stream<CaseRecord> watchCaseForEdit(String caseId) {
    return CaseEditRecordResolver(this).watchForEdit(caseId);
  }

  @override
  Future<String> createCase(CaseRecord record) async {
    final policyError = CaseWritePolicy.validateForCreate(record);
    if (policyError != null) {
      throw FormatException(policyError);
    }
    CaseRecordModel.assertValidForWrite(record);

    final caseId = record.caseId.trim();
    if (caseId.isEmpty) {
      throw FormatException('Case id must be allocated before create.');
    }
    final ref = _firestore.collection(FirestorePaths.cases).doc(caseId);

    final existing = await _readCaseFromCache(ref);
    if (existing != null && _matchesCreateIntent(existing, record)) {
      return caseId;
    }

    final model = CaseRecordModel.fromEntity(
      CaseRecord(
        caseId: caseId,
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
    final payload = model.toFirestoreCreate();

    await commitWriteLocalFirst(
      write: ref.set(payload),
      isPersistedLocally: () => documentExistsInCache(ref),
    );
    return caseId;
  }

  @override
  Future<void> updateCase(CaseRecord record) async {
    final ref = _firestore.collection(FirestorePaths.cases).doc(record.caseId);
    final existing = await _readCaseForUpdate(ref);
    if (existing == null) {
      throw StateError('Case not found.');
    }
    final policyError = CaseWritePolicy.validateForUpdate(
      updated: record,
      existing: existing,
    );
    if (policyError != null) {
      throw FormatException(policyError);
    }
    CaseRecordModel.assertValidForWrite(record);
    final model = CaseRecordModel.fromEntity(record);
    final payload = model.toFirestoreUpdate(createdAt: existing.createdAt);

    await commitWriteLocalFirst(
      write: ref.update(payload),
      isPersistedLocally: () async {
        final cached = await _readCaseFromCache(ref);
        if (cached == null) return false;
        return cached.notes == record.notes &&
            cached.caseStatus == record.caseStatus &&
            cached.demoName == record.demoName &&
            cached.age == record.age;
      },
    );
  }

  @override
  Stream<List<FollowUpTimelineEntry>> watchFollowUps(String caseId) {
    return _firestore
        .collection(FirestorePaths.cases)
        .doc(caseId)
        .collection(FirestorePaths.followUps)
        .orderBy('scheduledAt')
        .snapshotsWithCacheMetadata()
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
    final caseExists = await documentExistsInCache(caseRef);
    if (!caseExists) {
      final serverSnap = await caseRef
          .get(const GetOptions(source: Source.serverAndCache))
          .timeout(const Duration(seconds: 3));
      if (!serverSnap.exists) {
        throw StateError('Case not found.');
      }
    }

    final followUpId = followUp.followUpId.trim().isNotEmpty
        ? followUp.followUpId.trim()
        : caseRef.collection(FirestorePaths.followUps).doc().id;
    final ref = caseRef.collection(FirestorePaths.followUps).doc(followUpId);

    if (await documentExistsInCache(ref)) {
      return followUpId;
    }

    final model = FollowUpModel.fromEntity(
      FollowUp(
        followUpId: followUpId,
        caseId: followUp.caseId,
        scheduledAt: followUp.scheduledAt,
        completedAt: followUp.completedAt,
        status: followUp.status,
        notes: followUp.notes,
      ),
    );
    await commitWriteLocalFirst(
      write: ref.set(model.toFirestoreCreate(createdByUid: createdByUid)),
      isPersistedLocally: () => documentExistsInCache(ref),
    );
    return followUpId;
  }

  DocumentReference<Map<String, dynamic>> _caseRef(String caseId) {
    return _firestore.collection(FirestorePaths.cases).doc(caseId);
  }

  Future<CaseRecord?> _readCaseFromCache(
    DocumentReference<Map<String, dynamic>> ref,
  ) async {
    try {
      final snap = await ref.get(const GetOptions(source: Source.cache));
      if (!snap.exists || snap.data() == null) return null;
      return CaseRecordModel.fromFirestore(ref.id, snap.data()!).toEntity();
    } on FirebaseException {
      return null;
    }
  }

  Future<CaseRecord?> _readCaseForUpdate(
    DocumentReference<Map<String, dynamic>> ref,
  ) async {
    final cached = await _readCaseFromCache(ref);
    if (cached != null) return cached;
    try {
      final snap = await ref
          .get(const GetOptions(source: Source.serverAndCache))
          .timeout(const Duration(seconds: 3));
      if (!snap.exists || snap.data() == null) return null;
      return CaseRecordModel.fromFirestore(ref.id, snap.data()!).toEntity();
    } on TimeoutException {
      return cached;
    }
  }

  bool _matchesCreateIntent(CaseRecord cached, CaseRecord requested) {
    return cached.orgId == requested.orgId &&
        cached.demoName == requested.demoName &&
        cached.age == requested.age &&
        cached.barangay == requested.barangay &&
        cached.caseStatus == requested.caseStatus;
  }
}
