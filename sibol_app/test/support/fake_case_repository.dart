import 'package:sibol_app/core/domain/firestore_document_snapshot.dart';
import 'package:sibol_app/core/domain/firestore_list_snapshot.dart';
import 'package:sibol_app/features/cases/domain/case_edit_record_resolver.dart';
import 'package:sibol_app/features/cases/domain/entities/case_list_entry.dart';
import 'package:sibol_app/features/cases/domain/entities/case_record.dart';
import 'package:sibol_app/features/cases/domain/entities/follow_up.dart';
import 'package:sibol_app/features/cases/domain/entities/follow_up_timeline_entry.dart';
import 'package:sibol_app/features/cases/domain/follow_up_validation.dart';
import 'package:sibol_app/features/cases/domain/repositories/case_repository.dart';

class FakeCaseRepository implements CaseRepository {
  FakeCaseRepository({
    List<CaseRecord>? cases,
    Stream<FirestoreListSnapshot<CaseListEntry>>? casesStream,
    Map<String, Stream<FirestoreDocumentSnapshot<CaseRecord>>>? caseStreams,
    Map<String, Stream<List<FollowUpTimelineEntry>>>? followUpStreams,
  })  : _cases = List<CaseRecord>.from(cases ?? const []),
        _casesStream = casesStream,
        _caseStreams = caseStreams ?? {},
        _followUpStreams = followUpStreams ?? {};

  final List<CaseRecord> _cases;
  final Stream<FirestoreListSnapshot<CaseListEntry>>? _casesStream;
  int _idSeq = 0;
  final Map<String, Stream<FirestoreDocumentSnapshot<CaseRecord>>> _caseStreams;
  final List<FollowUp> _followUps = [];
  final Map<String, Stream<List<FollowUpTimelineEntry>>> _followUpStreams;

  @override
  String newCaseDocumentId() => 'fake-case-${++_idSeq}';

  @override
  Stream<FirestoreListSnapshot<CaseListEntry>> watchCasesForOrg(String orgId) {
    if (_casesStream != null) return _casesStream;
    final items = _cases
        .where((c) => c.orgId == orgId)
        .map(
          (c) => CaseListEntry(
            record: c,
            isFromCache: false,
            hasPendingWrites: false,
          ),
        )
        .toList();
    return Stream.value(
      FirestoreListSnapshot(items: items, isFromCache: false),
    );
  }

  @override
  Future<List<CaseRecord>> fetchCasesForOrg(String orgId) async =>
      _cases.where((c) => c.orgId == orgId).toList();

  @override
  Stream<FirestoreDocumentSnapshot<CaseRecord>> watchCase(String caseId) {
    return _caseStreams[caseId] ??
        Stream.value(const FirestoreDocumentSnapshot(data: null, isFromCache: false));
  }

  @override
  Future<CaseRecord?> fetchCasePreferCache(String caseId) async {
    for (final c in _cases) {
      if (c.caseId == caseId) return c;
    }
    return null;
  }

  @override
  Future<CaseRecord?> fetchCase(String caseId) async => fetchCasePreferCache(caseId);

  @override
  Stream<CaseRecord> watchCaseForEdit(String caseId) {
    return CaseEditRecordResolver(this).watchForEdit(caseId);
  }

  @override
  Future<String> createCase(CaseRecord record) async {
    final id = record.caseId.isEmpty ? newCaseDocumentId() : record.caseId;
    final existing = _cases.where((c) => c.caseId == id).toList();
    if (existing.isNotEmpty) return id;
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
  Stream<List<FollowUpTimelineEntry>> watchFollowUps(String caseId) {
    return _followUpStreams[caseId] ??
        Stream<List<FollowUpTimelineEntry>>.value(const []);
  }

  @override
  Future<String> createFollowUp({
    required FollowUp followUp,
    required String createdByUid,
  }) async {
    final notesError = FollowUpValidation.validateNotes(followUp.notes);
    if (notesError != null) throw FormatException(notesError);
    final id = followUp.followUpId.isEmpty
        ? 'fu-${++_idSeq}'
        : followUp.followUpId;
    final stored = FollowUp(
      followUpId: id,
      caseId: followUp.caseId,
      scheduledAt: followUp.scheduledAt,
      completedAt: followUp.completedAt,
      status: followUp.status,
      notes: followUp.notes,
      createdAt: DateTime.now().toUtc(),
      createdByUid: createdByUid,
    );
    _followUps.add(stored);
    return id;
  }
}
