import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sibol_app/config/emulator_firebase_options.dart';
import 'package:sibol_app/features/offline/data/offline_sync_service.dart';
import 'package:sibol_app/features/offline/domain/pending_operation.dart';
import 'support/memory_pending_operation_store.dart';

class MockFirebaseAuth extends Mock implements FirebaseAuth {}

class MockUser extends Mock implements User {}

class MockFirebaseFunctions extends Mock implements FirebaseFunctions {}

class MockHttpsCallable extends Mock implements HttpsCallable {}

class MockHttpsCallableResult extends Mock
    implements HttpsCallableResult<Map<String, dynamic>> {}

class MockConnectivity extends Mock implements Connectivity {}

class MockFirebaseFirestore extends Mock implements FirebaseFirestore {}

void main() {
  late MemoryPendingOperationStore store;
  late MockFirebaseAuth auth;
  late MockFirebaseFunctions functions;
  late MockConnectivity connectivity;
  late OfflineSyncService service;

  setUpAll(() {
    registerFallbackValue(<String, dynamic>{});
  });

  setUp(() {
    store = MemoryPendingOperationStore();
    auth = MockFirebaseAuth();
    functions = MockFirebaseFunctions();
    connectivity = MockConnectivity();
    service = OfflineSyncService(
      store: store,
      functions: functions,
      firestore: MockFirebaseFirestore(),
      auth: auth,
      connectivity: connectivity,
      resolveActiveFirebaseProjectId: () => EmulatorFirebaseOptions.projectId,
    );
  });

  PendingOperation pendingAck(String ownerUid, {String operationId = 'ack-op-1'}) {
    return PendingOperation(
      operationId: operationId,
      ownerUid: ownerUid,
      kind: PendingOperationKind.barangayAcknowledge,
      state: PendingOperationState.waitingToSubmit,
      createdAt: DateTime.utc(2026, 3, 1),
      payload: {'requestId': 'req-1', 'orgId': 'barangay03'},
      firebaseProjectId: EmulatorFirebaseOptions.projectId,
    );
  }

  test('pending operation survives reload with same operation identity', () async {
    final user = MockUser();
    when(() => user.uid).thenReturn('user-a');
    when(() => auth.currentUser).thenReturn(user);

    final op = pendingAck('user-a');
    await service.enqueue(op);
    final reloaded = await store.loadForUser('user-a');
    expect(reloaded.single.operationId, 'ack-op-1');
    expect(reloaded.single.ownerUid, 'user-a');
  });

  test('user B cannot read or process user A pending queue', () async {
    await store.upsert(pendingAck('user-a'));

    final userB = MockUser();
    when(() => userB.uid).thenReturn('user-b');
    when(() => auth.currentUser).thenReturn(userB);

    expect(await service.pendingForUser('user-a'), isEmpty);
    await service.syncForUser('user-a');
    final stillPending = await store.loadForUser('user-a');
    expect(stillPending.single.state, PendingOperationState.waitingToSubmit);
  });

  test('user A can sync after sign-in when authorized', () async {
    final userA = MockUser();
    when(() => userA.uid).thenReturn('user-a');
    when(() => auth.currentUser).thenReturn(userA);
    when(() => connectivity.checkConnectivity())
        .thenAnswer((_) async => [ConnectivityResult.wifi]);

    final callable = MockHttpsCallable();
    final result = MockHttpsCallableResult();
    when(() => functions.httpsCallable('regAcknowledgeTeenAssistanceRequest'))
        .thenReturn(callable);
    when(() => callable.call(any())).thenAnswer(
      (_) async => result,
    );
    when(() => result.data).thenReturn({
      'requestId': 'req-1',
      'status': 'acknowledged',
      'orgId': 'barangay03',
      'idempotent': false,
    });

    await store.upsert(pendingAck('user-a'));
    await service.syncForUser('user-a');

    final after = await store.loadForUser('user-a');
    expect(after.single.state, PendingOperationState.submittedConfirmed);
  });

  test('permanent authorization failure does not stay retryable', () async {
    final userA = MockUser();
    when(() => userA.uid).thenReturn('user-a');
    when(() => auth.currentUser).thenReturn(userA);
    when(() => connectivity.checkConnectivity())
        .thenAnswer((_) async => [ConnectivityResult.wifi]);

    final callable = MockHttpsCallable();
    when(() => functions.httpsCallable('regAcknowledgeTeenAssistanceRequest'))
        .thenReturn(callable);
    when(() => callable.call(any())).thenThrow(
      FirebaseFunctionsException(code: 'permission-denied', message: 'Denied.'),
    );

    await store.upsert(pendingAck('user-a'));
    await service.syncForUser('user-a');

    final after = await store.loadForUser('user-a');
    expect(after.single.state, PendingOperationState.failedPermanent);
  });

  test('enqueue rejects operations for a different signed-in user', () async {
    final userA = MockUser();
    when(() => userA.uid).thenReturn('user-a');
    when(() => auth.currentUser).thenReturn(userA);

    expect(
      () => service.enqueue(pendingAck('user-b')),
      throwsStateError,
    );
  });

  PendingOperation pendingReferral(String ownerUid) {
    return PendingOperation(
      operationId: 'ref-op-1',
      ownerUid: ownerUid,
      kind: PendingOperationKind.barangayReferral,
      state: PendingOperationState.waitingToSubmit,
      createdAt: DateTime.utc(2026, 3, 1),
      payload: {
        'assistanceRequestId': 'assist-1',
        'disclosureMode': 'minimum',
        'referralPurposeCode': 'hospital_coordination',
        'coordinationNeedCodes': 'schedule_coordination',
      },
      firebaseProjectId: EmulatorFirebaseOptions.projectId,
    );
  }

  test('queued referral payload excludes identifying profile fields', () {
    final op = pendingReferral('user-a');
    expect(op.payload.keys, isNot(contains('legalName')));
    expect(op.payload.keys, isNot(contains('teenProfile')));
    expect(op.payload.keys, isNot(contains('barangayReferralSummary')));
  });

  test('structured referral sync calls createCoordinationReferral without free text', () async {
    final userA = MockUser();
    when(() => userA.uid).thenReturn('user-a');
    when(() => auth.currentUser).thenReturn(userA);
    when(() => connectivity.checkConnectivity())
        .thenAnswer((_) async => [ConnectivityResult.wifi]);

    final callable = MockHttpsCallable();
    final result = MockHttpsCallableResult();
    when(() => functions.httpsCallable('createCoordinationReferral'))
        .thenReturn(callable);
    when(() => callable.call<Map<String, dynamic>>(any())).thenAnswer((invocation) async {
      final args = invocation.positionalArguments.first as Map<String, dynamic>;
      expect(args.containsKey('barangayReferralSummary'), isFalse);
      expect(args['disclosureMode'], 'minimum');
      expect(args['assistanceRequestId'], 'assist-1');
      return result;
    });
    when(() => result.data).thenReturn({
      'threadId': 'thread-1',
      'displayRef': 'SIBOL-REF-TEST',
      'disclosureMode': 'minimum',
    });

    await store.upsert(pendingReferral('user-a'));
    await service.syncForUser('user-a');

    final after = await store.loadForUser('user-a');
    expect(after.single.state, PendingOperationState.submittedConfirmed);
  });

  test('authorization revalidation failure on referral sync is retryable', () async {
    final userA = MockUser();
    when(() => userA.uid).thenReturn('user-a');
    when(() => auth.currentUser).thenReturn(userA);
    when(() => connectivity.checkConnectivity())
        .thenAnswer((_) async => [ConnectivityResult.wifi]);

    final callable = MockHttpsCallable();
    when(() => functions.httpsCallable('createCoordinationReferral'))
        .thenReturn(callable);
    when(() => callable.call<Map<String, dynamic>>(any())).thenThrow(
      FirebaseFunctionsException(
        code: 'failed-precondition',
        message: 'Authorization expired or withdrawn.',
      ),
    );

    await store.upsert(
      PendingOperation(
        operationId: 'ref-op-auth-expired',
        ownerUid: 'user-a',
        kind: PendingOperationKind.barangayReferral,
        state: PendingOperationState.waitingToSubmit,
        createdAt: DateTime.utc(2026, 3, 1),
        payload: {
          'assistanceRequestId': 'assist-1',
          'disclosureMode': 'authorized',
          'referralPurposeCode': 'hospital_coordination',
          'coordinationNeedCodes': 'schedule_coordination',
          'authorizationId': 'auth-expired',
        },
        firebaseProjectId: EmulatorFirebaseOptions.projectId,
      ),
    );
    await service.syncForUser('user-a');

    final after = await store.loadForUser('user-a');
    expect(after.single.state, PendingOperationState.failedRetryable);
  });
}
