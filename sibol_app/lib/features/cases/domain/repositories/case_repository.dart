import 'package:sibol_app/core/domain/firestore_document_snapshot.dart';
import 'package:sibol_app/core/domain/firestore_list_snapshot.dart';
import 'package:sibol_app/features/cases/domain/entities/case_record.dart';
import 'package:sibol_app/features/cases/domain/entities/follow_up.dart';

abstract class CaseRepository {
  Stream<FirestoreListSnapshot<CaseRecord>> watchCasesForOrg(String orgId);

  Future<List<CaseRecord>> fetchCasesForOrg(String orgId);

  /// Live case document; `null` when the document does not exist.
  Stream<FirestoreDocumentSnapshot<CaseRecord>> watchCase(String caseId);

  /// Creates a case document; returns the generated document id.
  Future<String> createCase(CaseRecord record);

  Future<void> updateCase(CaseRecord record);

  Stream<List<FollowUp>> watchFollowUps(String caseId);

  /// Records a follow-up under [followUp.caseId]; returns the document id.
  Future<String> createFollowUp(FollowUp followUp);
}
