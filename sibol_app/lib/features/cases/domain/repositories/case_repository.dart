import 'package:sibol_app/core/domain/firestore_document_snapshot.dart';
import 'package:sibol_app/core/domain/firestore_list_snapshot.dart';
import 'package:sibol_app/features/cases/domain/entities/case_list_entry.dart';
import 'package:sibol_app/features/cases/domain/entities/case_record.dart';
import 'package:sibol_app/features/cases/domain/entities/follow_up.dart';
import 'package:sibol_app/features/cases/domain/entities/follow_up_timeline_entry.dart';

abstract class CaseRepository {
  Stream<FirestoreListSnapshot<CaseListEntry>> watchCasesForOrg(String orgId);

  /// Stable id for a new case document (allocate once per create screen session).
  String newCaseDocumentId();

  Future<List<CaseRecord>> fetchCasesForOrg(String orgId);

  /// Live case document; `null` when the document does not exist.
  Stream<FirestoreDocumentSnapshot<CaseRecord>> watchCase(String caseId);

  /// Reads a case document from the local Firestore cache when present.
  Future<CaseRecord?> fetchCasePreferCache(String caseId);

  /// One-shot read (cache then server per SDK defaults).
  Future<CaseRecord?> fetchCase(String caseId);

  /// Cache-first stream for the case edit form.
  Stream<CaseRecord> watchCaseForEdit(String caseId);

  /// Creates a case document; returns the generated document id.
  Future<String> createCase(CaseRecord record);

  Future<void> updateCase(CaseRecord record);

  Stream<List<FollowUpTimelineEntry>> watchFollowUps(String caseId);

  /// Records a follow-up under [followUp.caseId]; returns the document id.
  Future<String> createFollowUp({
    required FollowUp followUp,
    required String createdByUid,
    String? createdByDisplayName,
    String? createdByStaffEmail,
  });
}
