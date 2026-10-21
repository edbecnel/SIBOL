import 'package:sibol_app/features/cases/domain/entities/case_record.dart';
import 'package:sibol_app/features/cases/domain/entities/follow_up.dart';

abstract class CaseRepository {
  Stream<List<CaseRecord>> watchCases();

  Future<List<CaseRecord>> fetchCases();

  /// Live case document; `null` when the document does not exist.
  Stream<CaseRecord?> watchCase(String caseId);

  /// Creates a case document; returns the generated document id.
  Future<String> createCase(CaseRecord record);

  Future<void> updateCase(CaseRecord record);

  Stream<List<FollowUp>> watchFollowUps(String caseId);
}
