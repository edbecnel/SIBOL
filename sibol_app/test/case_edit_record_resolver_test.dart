import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:sibol_app/core/domain/firestore_document_snapshot.dart';
import 'package:sibol_app/core/domain/firestore_list_snapshot.dart';
import 'package:sibol_app/features/cases/domain/case_edit_record_resolver.dart';
import 'package:sibol_app/features/cases/domain/case_edit_unavailable.dart';
import 'package:sibol_app/features/cases/domain/case_status.dart';
import 'package:sibol_app/features/cases/domain/entities/case_list_entry.dart';
import 'package:sibol_app/features/cases/domain/entities/case_record.dart';
import 'package:sibol_app/features/cases/domain/entities/follow_up.dart';
import 'package:sibol_app/features/cases/domain/entities/follow_up_timeline_entry.dart';
import 'package:sibol_app/features/cases/domain/repositories/case_repository.dart';
import 'package:sibol_app/features/reporting/domain/report_status.dart';

class _HarnessRepo implements CaseRepository {
  _HarnessRepo({
    this.cache,
    this.fetchResult,
    this.watchStream,
  });

  final CaseRecord? cache;
  final CaseRecord? fetchResult;
  final Stream<FirestoreDocumentSnapshot<CaseRecord>>? watchStream;

  @override
  Future<CaseRecord?> fetchCasePreferCache(String caseId) async => cache;

  @override
  Future<CaseRecord?> fetchCase(String caseId) async {
    if (fetchResult != null) return fetchResult;
    return Future<CaseRecord?>.delayed(const Duration(days: 1), () => null);
  }

  @override
  Stream<CaseRecord> watchCaseForEdit(String caseId) =>
      CaseEditRecordResolver(this).watchForEdit(caseId);

  @override
  Stream<FirestoreDocumentSnapshot<CaseRecord>> watchCase(String caseId) {
    return watchStream ?? const Stream.empty();
  }

  @override
  String newCaseDocumentId() => 'id-1';

  @override
  Stream<FirestoreListSnapshot<CaseListEntry>> watchCasesForOrg(String orgId) =>
      throw UnimplementedError();

  @override
  Future<List<CaseRecord>> fetchCasesForOrg(String orgId) =>
      throw UnimplementedError();

  @override
  Future<String> createCase(CaseRecord record) => throw UnimplementedError();

  @override
  Future<void> updateCase(CaseRecord record) => throw UnimplementedError();

  @override
  Stream<List<FollowUpTimelineEntry>> watchFollowUps(String caseId) =>
      throw UnimplementedError();

  @override
  Future<String> createFollowUp({
    required FollowUp followUp,
    required String createdByUid,
  }) =>
      throw UnimplementedError();
}

CaseRecord _record({String caseId = 'case-1', String demoName = 'Demo'}) {
  return CaseRecord(
    caseId: caseId,
    demoName: demoName,
    age: 16,
    barangay: 'Barangay 3, Balingasag',
    orgId: 'barangay03',
    caseStatus: CaseStatus.active,
    registeredAt: DateTime.utc(2026, 4, 1),
    notes: 'notes',
    createdAt: DateTime.utc(2026, 4, 1),
    updatedAt: DateTime.utc(2026, 4, 1),
    reportStatus: ReportStatus.notSubmitted,
  );
}

void main() {
  test('emits cached record without waiting for server fetch', () async {
    final record = _record(demoName: 'Maria Offline Test');
    final repo = _HarnessRepo(cache: record);
    final values = await repo
        .watchCaseForEdit(record.caseId)
        .take(1)
        .toList();
    expect(values.single.demoName, 'Maria Offline Test');
    expect(values.single.caseId, record.caseId);
  });

  test('errors when case missing locally and server bootstrap unavailable',
      () async {
    final repo = _HarnessRepo(cache: null, fetchResult: null);
    await expectLater(
      repo.watchCaseForEdit('missing-case'),
      emitsError(isA<CaseEditUnavailable>()),
    );
  });

  test('applies later watch updates while preserving case id', () async {
    final initial = _record();
    final updated = _record(demoName: 'Updated name');
    final controller =
        StreamController<FirestoreDocumentSnapshot<CaseRecord>>();
    final repo = _HarnessRepo(
      cache: initial,
      watchStream: controller.stream,
    );

    final emissions = <CaseRecord>[];
    final sub = repo.watchCaseForEdit(initial.caseId).listen(emissions.add);
    await Future<void>.delayed(const Duration(milliseconds: 30));
    controller.add(
      FirestoreDocumentSnapshot(data: updated, isFromCache: true),
    );
    await Future<void>.delayed(const Duration(milliseconds: 30));
    await sub.cancel();
    await controller.close();

    expect(emissions.length, greaterThanOrEqualTo(2));
    expect(emissions.first.caseId, initial.caseId);
    expect(emissions.last.demoName, 'Updated name');
    expect(emissions.last.caseId, initial.caseId);
  });
}
