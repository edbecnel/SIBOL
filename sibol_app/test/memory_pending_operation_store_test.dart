import 'package:flutter_test/flutter_test.dart';
import 'package:sibol_app/features/offline/domain/pending_operation.dart';
import 'package:sibol_app/features/offline/domain/pending_operation_retention.dart';

import 'support/memory_pending_operation_store.dart';

void main() {
  test('memory store applies terminal retention on save', () async {
    final store = MemoryPendingOperationStore();
    final unresolved = PendingOperation(
      operationId: 'pending-1',
      ownerUid: 'user-a',
      kind: PendingOperationKind.teenAssistanceSubmit,
      state: PendingOperationState.savedLocally,
      createdAt: DateTime.utc(2026, 2, 1),
      payload: {'category': 'generalSupport', 'description': 'demo text here'},
    );
    for (var i = 0; i < pendingOperationMaxTerminalRecords + 5; i++) {
      await store.upsert(
        PendingOperation(
          operationId: 'done-$i',
          ownerUid: 'user-a',
          kind: PendingOperationKind.barangayAcknowledge,
          state: PendingOperationState.submittedConfirmed,
          createdAt: DateTime.utc(2026, 1, i + 1),
          payload: {'requestId': 'r', 'orgId': 'barangay03'},
        ),
      );
    }
    await store.upsert(unresolved);
    final all = await store.loadForUser('user-a');
    expect(all.any((o) => o.operationId == 'pending-1'), isTrue);
    expect(
      all.where((o) => o.state == PendingOperationState.submittedConfirmed).length,
      pendingOperationMaxTerminalRecords,
    );
  });
}
