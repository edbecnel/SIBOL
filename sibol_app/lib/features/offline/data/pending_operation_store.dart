import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:sibol_app/features/offline/domain/pending_operation.dart';

const _storageKeyPrefix = 'sibol.pending_ops.v1';

class PendingOperationStore {
  PendingOperationStore(this._storage);

  final FlutterSecureStorage _storage;

  String _keyForUser(String uid) => '$_storageKeyPrefix.$uid';

  Future<List<PendingOperation>> loadForUser(String uid) async {
    final raw = await _storage.read(key: _keyForUser(uid));
    if (raw == null || raw.isEmpty) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map((e) => PendingOperation.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<void> saveForUser(String uid, List<PendingOperation> operations) async {
    final encoded = jsonEncode(operations.map((o) => o.toJson()).toList());
    await _storage.write(key: _keyForUser(uid), value: encoded);
  }

  Future<void> upsert(PendingOperation operation) async {
    final list = await loadForUser(operation.ownerUid);
    final next = [...list.where((o) => o.operationId != operation.operationId), operation];
    await saveForUser(operation.ownerUid, next);
  }

  Future<void> remove(String ownerUid, String operationId) async {
    final list = await loadForUser(ownerUid);
    await saveForUser(
      ownerUid,
      list.where((o) => o.operationId != operationId).toList(),
    );
  }
}
