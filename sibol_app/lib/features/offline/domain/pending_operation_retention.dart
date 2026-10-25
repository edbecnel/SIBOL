import 'package:sibol_app/features/offline/domain/pending_operation.dart';

/// Maximum terminal pending-operation records kept per user (newest first).
const pendingOperationMaxTerminalRecords = 25;

bool isUnresolvedPendingState(PendingOperationState state) {
  return state == PendingOperationState.savedLocally ||
      state == PendingOperationState.waitingToSubmit ||
      state == PendingOperationState.submitting ||
      state == PendingOperationState.failedRetryable;
}

List<PendingOperation> pruneTerminalPendingOperations(
  List<PendingOperation> operations, {
  int maxTerminal = pendingOperationMaxTerminalRecords,
}) {
  final unresolved = <PendingOperation>[];
  final terminal = <PendingOperation>[];
  for (final op in operations) {
    if (isUnresolvedPendingState(op.state)) {
      unresolved.add(op);
    } else {
      terminal.add(op);
    }
  }
  terminal.sort((a, b) => b.createdAt.compareTo(a.createdAt));
  return [...unresolved, ...terminal.take(maxTerminal)];
}
