import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sibol_app/features/offline/data/offline_sync_service.dart';
import 'package:sibol_app/features/offline/domain/pending_operation.dart';
import 'support/memory_pending_operation_store.dart';

class MockFirebaseAuth extends Mock implements FirebaseAuth {}

class MockUser extends Mock implements User {}

class MockFirebaseFunctions extends Mock implements FirebaseFunctions {}

class MockHttpsCallable extends Mock implements HttpsCallable {}

class MockHttpsCallableResult extends Mock implements HttpsCallableResult {}

class MockConnectivity extends Mock implements Connectivity {}

class MockFirebaseFirestore extends Mock implements FirebaseFirestore {}

void main() {
  late MemoryPendingOperationStore store;
  late MockFirebaseAuth auth;
  late MockFirebaseFunctions functions;
  late MockConnectivity connectivity;
  late OfflineSyncService service;

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
}
