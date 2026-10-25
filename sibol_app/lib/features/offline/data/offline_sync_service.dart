import 'dart:async';
import 'dart:math';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:sibol_app/features/coordination/data/repositories/coordination_repository_impl.dart';
import 'package:sibol_app/features/offline/data/offline_sync_error.dart';
import 'package:sibol_app/features/offline/data/pending_operation_store.dart';
import 'package:sibol_app/features/offline/domain/pending_operation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class OfflineSyncService {
  OfflineSyncService({
    required PendingOperationPersistence store,
    required FirebaseFunctions functions,
    required FirebaseFirestore firestore,
    required FirebaseAuth auth,
    Connectivity? connectivity,
  })  : _store = store,
        _functions = functions,
        _firestore = firestore,
        _auth = auth,
        _connectivity = connectivity ?? Connectivity();

  final PendingOperationPersistence _store;
  final FirebaseFunctions _functions;
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final Connectivity _connectivity;

  static const maxAttempts = 8;

  String? _authenticatedUid() => _auth.currentUser?.uid;

  Future<bool> hasConnectivity() async {
    final result = await _connectivity.checkConnectivity();
    return !result.contains(ConnectivityResult.none);
  }

  Future<void> enqueue(PendingOperation operation) async {
    final current = _authenticatedUid();
    if (current == null || current != operation.ownerUid) {
      throw StateError('Cannot queue operations for another signed-in account.');
    }
    await _store.upsert(operation);
  }

  Future<List<PendingOperation>> pendingForUser(String uid) async {
    final current = _authenticatedUid();
    if (current == null || current != uid) return [];
    final all = await _store.loadForUser(uid);
    return all
        .where(
          (o) =>
              o.ownerUid == uid &&
              (o.state == PendingOperationState.savedLocally ||
                  o.state == PendingOperationState.waitingToSubmit ||
                  o.state == PendingOperationState.failedRetryable),
        )
        .toList();
  }

  Future<void> syncForUser(String uid) async {
    final current = _authenticatedUid();
    if (current == null || current != uid) return;
    if (!await hasConnectivity()) return;
    final ops = await _store.loadForUser(uid);
    for (final op in ops) {
      if (op.ownerUid != uid) continue;
      if (op.state == PendingOperationState.submittedConfirmed ||
          op.state == PendingOperationState.failedPermanent ||
          op.state == PendingOperationState.conflict) {
        continue;
      }
      await _processOne(op, authenticatedUid: uid);
    }
  }

  /// Runs one pending operation and returns its persisted state (for UI feedback).
  Future<PendingOperation> processOperation(PendingOperation op) async {
    final current = _authenticatedUid();
    if (current == null || current != op.ownerUid) {
      return op;
    }
    await _processOne(op, authenticatedUid: current);
    final all = await _store.loadForUser(op.ownerUid);
    return all.firstWhere(
      (o) => o.operationId == op.operationId,
      orElse: () => op,
    );
  }

  Future<void> _processOne(
    PendingOperation op, {
    required String authenticatedUid,
  }) async {
    if (op.ownerUid != authenticatedUid) return;

    if (op.attemptCount >= maxAttempts) {
      await _store.upsert(
        op.copyWith(
          state: PendingOperationState.failedPermanent,
          lastError: 'Maximum retry attempts reached.',
        ),
      );
      return;
    }

    final inFlight = op.copyWith(
      state: PendingOperationState.submitting,
      lastAttemptAt: DateTime.now(),
      attemptCount: op.attemptCount + 1,
    );
    await _store.upsert(inFlight);

    try {
      switch (op.kind) {
        case PendingOperationKind.teenAssistanceSubmit:
          await _syncTeenAssistance(inFlight);
        case PendingOperationKind.barangayAcknowledge:
          await _syncBarangayAck(inFlight);
        case PendingOperationKind.barangayReferral:
          await _syncBarangayReferral(inFlight);
      }
    } catch (e, st) {
      debugPrint('Offline sync failed: $e');
      debugPrint('$st');
      final failure = classifySyncFailure(e);
      await _store.upsert(
        inFlight.copyWith(
          state: failure.state,
          lastError: failure.message,
        ),
      );
      if (failure.state == PendingOperationState.failedRetryable) {
        await Future<void>.delayed(
          Duration(
            milliseconds: min(30000, 1000 * pow(2, inFlight.attemptCount).toInt()),
          ),
        );
      }
    }
  }

  Future<void> _syncTeenAssistance(PendingOperation op) async {
    final result = await _functions.httpsCallable('regSubmitTeenAssistanceRequest').call({
      'idempotencyKey': op.operationId,
      'category': op.payload['category'],
      'description': op.payload['description'],
    });
    final data = Map<String, dynamic>.from(result.data as Map);
    await _store.upsert(
      op.copyWith(
        state: PendingOperationState.submittedConfirmed,
        serverRequestId: data['requestId'] as String?,
        lastError: null,
      ),
    );
  }

  Future<void> _syncBarangayAck(PendingOperation op) async {
    final orgId = op.payload['orgId'];
    final requestId = op.payload['requestId'];
    if (orgId == null || orgId.isEmpty || requestId == null || requestId.isEmpty) {
      throw StateError(
        'Pending acknowledgment is missing routing. Retry from the request screen.',
      );
    }
    final result =
        await _functions.httpsCallable('regAcknowledgeTeenAssistanceRequest').call({
      'idempotencyKey': op.operationId,
      'requestId': requestId,
      'orgId': orgId,
    });
    final data = Map<String, dynamic>.from(result.data as Map);
    await _store.upsert(
      op.copyWith(
        state: PendingOperationState.submittedConfirmed,
        serverRequestId: data['requestId'] as String?,
        lastError: null,
      ),
    );
  }

  Future<void> _syncBarangayReferral(PendingOperation op) async {
    final repo = CoordinationRepositoryImpl(_firestore, _functions);
    try {
      await repo.createCoordinationReferral(
        assistanceRequestId: op.payload['assistanceRequestId']!,
        barangayReferralSummary: op.payload['summary']!,
      );
    } on FirebaseFunctionsException catch (e) {
      final failure = classifySyncFailure(e);
      if (failure.state == PendingOperationState.conflict) {
        await _store.upsert(
          op.copyWith(
            state: PendingOperationState.conflict,
            lastError: failure.message,
          ),
        );
        return;
      }
      rethrow;
    }
    await _store.upsert(
      op.copyWith(
        state: PendingOperationState.submittedConfirmed,
        lastError: null,
      ),
    );
  }
}
