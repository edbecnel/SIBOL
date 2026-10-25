import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:sibol_app/features/offline/domain/pending_operation.dart';
import 'package:sibol_app/features/offline/domain/pending_operation_retention.dart';

const _storageKeyPrefix = 'sibol.pending_ops.v1';

abstract class PendingOperationPersistence {
  Future<List<PendingOperation>> loadForUser(String uid);
  Future<void> saveForUser(String uid, List<PendingOperation> operations);
  Future<void> upsert(PendingOperation operation);
  Future<void> remove(String ownerUid, String operationId);
}

class PendingOperationStore implements PendingOperationPersistence {
  PendingOperationStore(this._storage);

  final FlutterSecureStorage _storage;

  String _keyForUser(String uid) => '$_storageKeyPrefix.$uid';

  @override
  Future<List<PendingOperation>> loadForUser(String uid) async {
    final raw = await _storage.read(key: _keyForUser(uid));
    if (raw == null || raw.isEmpty) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map((e) => PendingOperation.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  @override
  Future<void> saveForUser(String uid, List<PendingOperation> operations) async {
    final pruned = pruneTerminalPendingOperations(operations);
    final encoded = jsonEncode(pruned.map((o) => o.toJson()).toList());
    await _storage.write(key: _keyForUser(uid), value: encoded);
  }

  @override
  Future<void> upsert(PendingOperation operation) async {
    final list = await loadForUser(operation.ownerUid);
    final next = [...list.where((o) => o.operationId != operation.operationId), operation];
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
