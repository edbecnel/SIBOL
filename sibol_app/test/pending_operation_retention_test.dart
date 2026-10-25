import 'package:flutter_test/flutter_test.dart';
import 'package:sibol_app/features/offline/domain/pending_operation.dart';
import 'package:sibol_app/features/offline/domain/pending_operation_retention.dart';

void main() {
  PendingOperation op(
    String id,
    PendingOperationState state, {
    DateTime? createdAt,
  }) {
    return PendingOperation(
      operationId: id,
      ownerUid: 'user-a',
      kind: PendingOperationKind.barangayAcknowledge,
      state: state,
      createdAt: createdAt ?? DateTime.utc(2026, 1, 1),
      payload: {'requestId': 'r1', 'orgId': 'barangay03'},
    );
  }

  test('preserves all unresolved operations when pruning', () {
    final input = [
      op('u1', PendingOperationState.savedLocally),
      op('u2', PendingOperationState.failedRetryable),
      op('u3', PendingOperationState.submitting),
    ];
    final pruned = pruneTerminalPendingOperations(input, maxTerminal: 1);
    expect(pruned.length, 3);
  });

  test('bounds terminal records without dropping unresolved', () {
    final terminals = List.generate(
      30,
      (i) => op(
        't$i',
        PendingOperationState.submittedConfirmed,
        createdAt: DateTime.utc(2026, 1, i + 1),
      ),
    );
    final unresolved = op('keep', PendingOperationState.waitingToSubmit);
    final pruned = pruneTerminalPendingOperations(
      [...terminals, unresolved],
      maxTerminal: 25,
    );
    expect(pruned.where((o) => o.operationId == 'keep').length, 1);
    expect(
      pruned.where((o) => o.state == PendingOperationState.submittedConfirmed).length,
      25,
    );
  });
}
