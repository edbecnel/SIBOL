import 'package:sibol_app/features/cases/domain/entities/case_record.dart';
import 'package:sibol_app/features/cases/domain/entities/follow_up.dart';
import 'package:sibol_app/features/cases/domain/repositories/case_repository.dart';

class FakeCaseRepository implements CaseRepository {
  FakeCaseRepository({
    List<CaseRecord>? cases,
    Map<String, Stream<CaseRecord?>>? caseStreams,
    Map<String, Stream<List<FollowUp>>>? followUpStreams,
  })  : _cases = cases ?? const [],
        _caseStreams = caseStreams ?? {},
        _followUpStreams = followUpStreams ?? {};

  final List<CaseRecord> _cases;
  final Map<String, Stream<CaseRecord?>> _caseStreams;
  final Map<String, Stream<List<FollowUp>>> _followUpStreams;

  @override
  Stream<List<CaseRecord>> watchCases() => Stream.value(_cases);

  @override
  Future<List<CaseRecord>> fetchCases() async => _cases;

  @override
  Stream<CaseRecord?> watchCase(String caseId) {
    return _caseStreams[caseId] ?? Stream<CaseRecord?>.value(null);
  }

  @override
  Stream<List<FollowUp>> watchFollowUps(String caseId) {
    return _followUpStreams[caseId] ?? Stream<List<FollowUp>>.value(const []);
  }
}
