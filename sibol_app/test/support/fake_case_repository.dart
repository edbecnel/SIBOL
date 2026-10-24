import 'package:sibol_app/features/cases/domain/entities/case_record.dart';
import 'package:sibol_app/features/cases/domain/entities/follow_up.dart';
import 'package:sibol_app/features/cases/domain/repositories/case_repository.dart';

class FakeCaseRepository implements CaseRepository {
  FakeCaseRepository({
    List<CaseRecord>? cases,
    Map<String, Stream<CaseRecord?>>? caseStreams,
    Map<String, Stream<List<FollowUp>>>? followUpStreams,
  })  : _cases = List<CaseRecord>.from(cases ?? const []),
        _caseStreams = caseStreams ?? {},
        _followUpStreams = followUpStreams ?? {};

  final List<CaseRecord> _cases;
  int _idSeq = 0;
  final Map<String, Stream<CaseRecord?>> _caseStreams;
  final Map<String, Stream<List<FollowUp>>> _followUpStreams;

  @override
  Stream<List<CaseRecord>> watchCasesForOrg(String orgId) => Stream.value(
        _cases.where((c) => c.orgId == orgId).toList(),
      );

  @override
  Future<List<CaseRecord>> fetchCasesForOrg(String orgId) async =>
      _cases.where((c) => c.orgId == orgId).toList();

  @override
  Stream<CaseRecord?> watchCase(String caseId) {
    return _caseStreams[caseId] ?? Stream<CaseRecord?>.value(null);
  }

  @override
  Future<String> createCase(CaseRecord record) async {
    final id = record.caseId.isEmpty
        ? 'fake-case-${++_idSeq}'
        : record.caseId;
    final stored = CaseRecord(
      caseId: id,
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
    );
    _cases.add(stored);
    return id;
  }

  @override
  Future<void> updateCase(CaseRecord record) async {
    final index = _cases.indexWhere((c) => c.caseId == record.caseId);
    if (index < 0) throw StateError('Case not found.');
    _cases[index] = record;
  }

  @override
  Stream<List<FollowUp>> watchFollowUps(String caseId) {
    return _followUpStreams[caseId] ?? Stream<List<FollowUp>>.value(const []);
  }
}
