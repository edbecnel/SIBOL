import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sibol_app/core/constants/firestore_paths.dart';
import 'package:sibol_app/features/reporting/data/repositories/report_repository_impl.dart';
import 'package:sibol_app/features/reporting/domain/barangay_report_aggregate.dart';

class MockFirebaseFirestore extends Mock implements FirebaseFirestore {}

class MockCollectionReference extends Mock
    implements CollectionReference<Map<String, dynamic>> {}

class MockDocumentReference extends Mock
    implements DocumentReference<Map<String, dynamic>> {}

class MockDocumentSnapshot extends Mock
    implements DocumentSnapshot<Map<String, dynamic>> {}

void main() {
  late MockFirebaseFirestore firestore;
  late MockCollectionReference collection;
  late MockDocumentReference docRef;
  late ReportRepositoryImpl repo;

  const reportId = 'rpt-test-001';
  const orgId = 'barangay03';
  const submittedByUid = 'bns-uid';

  BarangayReportAggregateCounts sampleCounts() {
    return const BarangayReportAggregateCounts(
      barangay: 'Barangay 3, Balingasag',
      totalCaseCount: 1,
      activeCaseCount: 1,
      followUpScheduledCount: 0,
      followUpCompletedCount: 0,
      closedCaseCount: 0,
    );
  }

  Map<String, dynamic> matchingFirestoreData() {
    final counts = sampleCounts();
    return {
      'barangay': counts.barangay,
      'orgId': orgId,
      'submittedByUid': submittedByUid,
      'totalCaseCount': counts.totalCaseCount,
      'activeCaseCount': counts.activeCaseCount,
      'followUpScheduledCount': counts.followUpScheduledCount,
      'followUpCompletedCount': counts.followUpCompletedCount,
      'closedCaseCount': counts.closedCaseCount,
      'reportStatus': 'submitted',
      'submittedAt': Timestamp.now(),
      'acceptedAt': Timestamp.now(),
    };
  }

  setUpAll(() {
    registerFallbackValue(<String, dynamic>{});
  });

  setUp(() {
    firestore = MockFirebaseFirestore();
    collection = MockCollectionReference();
    docRef = MockDocumentReference();
    repo = ReportRepositoryImpl(firestore);

    when(() => firestore.collection(FirestorePaths.reports))
        .thenReturn(collection);
    when(() => collection.doc(any())).thenReturn(docRef);
  });

  test('createBarangayAggregateReport sets without preliminary get', () async {
    when(() => docRef.set(any())).thenAnswer((_) async {});

    await repo.createBarangayAggregateReport(
      reportId: reportId,
      submittedByUid: submittedByUid,
      orgId: orgId,
      counts: sampleCounts(),
    );

    verify(() => docRef.set(any())).called(1);
    verifyNever(() => docRef.get());
  });

  test('repeated set denied treats matching existing doc as success', () async {
    final snap = MockDocumentSnapshot();
    when(() => docRef.set(any())).thenThrow(
      FirebaseException(
        plugin: 'cloud_firestore',
        code: 'permission-denied',
        message: 'Update denied',
      ),
    );
    when(() => docRef.get()).thenAnswer((_) async => snap);
    when(() => snap.exists).thenReturn(true);
    when(() => snap.data()).thenReturn(matchingFirestoreData());

    await repo.createBarangayAggregateReport(
      reportId: reportId,
      submittedByUid: submittedByUid,
      orgId: orgId,
      counts: sampleCounts(),
    );

    verify(() => docRef.set(any())).called(1);
    verify(() => docRef.get()).called(1);
  });

  test('permission-denied with conflicting existing doc throws already-exists',
      () async {
    final snap = MockDocumentSnapshot();
    when(() => docRef.set(any())).thenThrow(
      FirebaseException(
        plugin: 'cloud_firestore',
        code: 'permission-denied',
        message: 'Update denied',
      ),
    );
    when(() => docRef.get()).thenAnswer((_) async => snap);
    when(() => snap.exists).thenReturn(true);
    when(() => snap.data()).thenReturn({
      ...matchingFirestoreData(),
      'totalCaseCount': 99,
    });

    expect(
      () => repo.createBarangayAggregateReport(
        reportId: reportId,
        submittedByUid: submittedByUid,
        orgId: orgId,
        counts: sampleCounts(),
      ),
      throwsA(
        isA<FirebaseException>().having((e) => e.code, 'code', 'already-exists'),
      ),
    );
  });

  test('genuine permission-denied on create propagates when doc unreadable',
      () async {
    when(() => docRef.set(any())).thenThrow(
      FirebaseException(
        plugin: 'cloud_firestore',
        code: 'permission-denied',
        message: 'Create denied',
      ),
    );
    when(() => docRef.get()).thenThrow(
      FirebaseException(
        plugin: 'cloud_firestore',
        code: 'permission-denied',
        message: 'Read denied',
      ),
    );

    expect(
      () => repo.createBarangayAggregateReport(
        reportId: reportId,
        submittedByUid: submittedByUid,
        orgId: orgId,
        counts: sampleCounts(),
      ),
      throwsA(
        isA<FirebaseException>().having((e) => e.code, 'code', 'permission-denied'),
      ),
    );
  });
}
