import 'package:sibol_app/features/cases/domain/entities/case_record.dart';
import 'package:sibol_app/features/cases/domain/entities/follow_up.dart';

abstract class CaseRepository {
  Stream<List<CaseRecord>> watchCases();

  Future<List<CaseRecord>> fetchCases();

  Stream<List<FollowUp>> watchFollowUps(String caseId);
}
