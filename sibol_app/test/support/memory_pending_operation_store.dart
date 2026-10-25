import 'package:sibol_app/features/offline/data/pending_operation_store.dart';
import 'package:sibol_app/features/offline/domain/pending_operation.dart';
import 'package:sibol_app/features/offline/domain/pending_operation_retention.dart';

/// In-memory [PendingOperationPersistence] for unit tests (simulates secure storage).
class MemoryPendingOperationStore implements PendingOperationPersistence {
  final Map<String, List<PendingOperation>> _byUser = {};

  @override
  Future<List<PendingOperation>> loadForUser(String uid) async {
    return List<PendingOperation>.from(_byUser[uid] ?? const []);
  }

  @override
  Future<void> saveForUser(String uid, List<PendingOperation> operations) async {
    _byUser[uid] = pruneTerminalPendingOperations(operations);
  }

  @override
  Future<void> upsert(PendingOperation operation) async {
    final list = await loadForUser(operation.ownerUid);
    final next = [
      ...list.where((o) => o.operationId != operation.operationId),
      operation,
    ];
    await saveForUser(operation.ownerUid, next);
  }

  @override
  Future<void> remove(String ownerUid, String operationId) async {
    final list = await loadForUser(ownerUid);
    await saveForUser(
      ownerUid,
      list.where((o) => o.operationId != operationId).toList(),
    );
  }
}
