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
      resolveActiveFirebaseProjectId: () => EmulatorFirebaseOptions.projectId,
    );
  });

  PendingOperation pendingAck(String ownerUid, {String? firebaseProjectId}) {
    return PendingOperation(
      operationId: 'ack-op-1',
      ownerUid: ownerUid,
      kind: PendingOperationKind.barangayAcknowledge,
      state: PendingOperationState.waitingToSubmit,
      createdAt: DateTime.utc(2026, 3, 1),
      payload: {'requestId': 'req-1', 'orgId': 'barangay03'},
      firebaseProjectId: firebaseProjectId,
    );
  }

  test('legacy unstamped operation is quarantined on sync', () async {
    final user = MockUser();
    when(() => user.uid).thenReturn('user-a');
    when(() => auth.currentUser).thenReturn(user);
    when(() => connectivity.checkConnectivity()).thenAnswer((_) async => [ConnectivityResult.wifi]);

    await store.upsert(pendingAck('user-a'));
    final summary = await service.syncForUser('user-a');
    expect(summary.stillPending, 0);
    final stored = await store.loadForUser('user-a');
    expect(stored.single.state, PendingOperationState.failedPermanent);
    expect(stored.single.lastError, contains('Legacy offline entry'));
  });

  test('cross-environment operation is quarantined on sync', () async {
    final user = MockUser();
    when(() => user.uid).thenReturn('user-a');
    when(() => auth.currentUser).thenReturn(user);
    when(() => connectivity.checkConnectivity()).thenAnswer((_) async => [ConnectivityResult.wifi]);

    await store.upsert(
      pendingAck('user-a', firebaseProjectId: 'sibol-286d0'),
    );
    await service.syncForUser('user-a');
    final stored = await store.loadForUser('user-a');
    expect(stored.single.state, PendingOperationState.failedPermanent);
    expect(stored.single.lastError, contains('belongs to sibol-286d0'));
  });
}
