import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:sibol_app/features/offline/domain/offline_firebase_environment.dart';
import 'package:sibol_app/features/offline/domain/pending_operation.dart';
import 'package:sibol_app/features/offline/domain/pending_operation_retention.dart';

abstract class PendingOperationPersistence {
  Future<List<PendingOperation>> loadForUser(String uid);
  Future<void> saveForUser(String uid, List<PendingOperation> operations);
  Future<void> upsert(PendingOperation operation);
  Future<void> remove(String ownerUid, String operationId);
}

class PendingOperationStore implements PendingOperationPersistence {
  PendingOperationStore(
    this._storage, {
    required String Function() resolveFirebaseProjectId,
  }) : _resolveFirebaseProjectId = resolveFirebaseProjectId;

  final FlutterSecureStorage _storage;
  final String Function() _resolveFirebaseProjectId;

  String _keyForUser(String uid) =>
      '${OfflineFirebaseEnvironment.storageKeyPrefix(_resolveFirebaseProjectId())}.$uid';

  String _legacyKeyForUser(String uid) =>
      '${OfflineFirebaseEnvironment.legacyStorageKeyPrefix()}.$uid';

  @override
  Future<List<PendingOperation>> loadForUser(String uid) async {
    final scoped = await _readList(_keyForUser(uid));
    final legacy = await _readList(_legacyKeyForUser(uid));
    if (legacy.isEmpty) return scoped;
    final scopedIds = scoped.map((o) => o.operationId).toSet();
    final merged = [
      ...scoped,
      ...legacy.where((o) => !scopedIds.contains(o.operationId)),
    ];
    return merged;
  }

  Future<List<PendingOperation>> _readList(String key) async {
    final raw = await _storage.read(key: key);
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
    final stamped = operation.firebaseProjectId == null
        ? operation.copyWith(firebaseProjectId: _resolveFirebaseProjectId())
        : operation;
    if (stamped.firebaseProjectId != _resolveFirebaseProjectId()) {
      throw StateError(
        'Cannot persist offline operation for Firebase project '
        '${stamped.firebaseProjectId}; active project is ${_resolveFirebaseProjectId()}.',
      );
    }
    final next = [
      ...list.where((o) => o.operationId != stamped.operationId),
      stamped,
    ];
    await saveForUser(stamped.ownerUid, next);
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
