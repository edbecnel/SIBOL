import 'dart:async';
import 'dart:math';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:sibol_app/features/coordination/data/repositories/coordination_repository_impl.dart';
import 'package:sibol_app/features/offline/data/pending_operation_store.dart';
import 'package:sibol_app/features/offline/domain/pending_operation.dart';
import 'package:sibol_app/features/teenager/data/repositories/assistance_request_repository_impl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class OfflineSyncService {
  OfflineSyncService({
    required PendingOperationStore store,
    required FirebaseFunctions functions,
    required FirebaseFirestore firestore,
    Connectivity? connectivity,
  })  : _store = store,
        _functions = functions,
        _firestore = firestore,
        _connectivity = connectivity ?? Connectivity();

  final PendingOperationStore _store;
  final FirebaseFunctions _functions;
  final FirebaseFirestore _firestore;
  final Connectivity _connectivity;

  static const maxAttempts = 8;

  Future<bool> hasConnectivity() async {
    final result = await _connectivity.checkConnectivity();
    return !result.contains(ConnectivityResult.none);
  }

  Future<void> enqueue(PendingOperation operation) async {
    await _store.upsert(operation);
  }

  Future<List<PendingOperation>> pendingForUser(String uid) async {
    final all = await _store.loadForUser(uid);
    return all
        .where(
          (o) =>
              o.state == PendingOperationState.savedLocally ||
              o.state == PendingOperationState.waitingToSubmit ||
              o.state == PendingOperationState.failedRetryable,
        )
        .toList();
  }

  Future<void> syncForUser(String uid) async {
    if (!await hasConnectivity()) return;
    final ops = await _store.loadForUser(uid);
    for (final op in ops) {
      if (op.ownerUid != uid) continue;
      if (op.state == PendingOperationState.submittedConfirmed ||
          op.state == PendingOperationState.failedPermanent ||
          op.state == PendingOperationState.conflict) {
        continue;
      }
      await _processOne(op);
    }
  }

  Future<void> _processOne(PendingOperation op) async {
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
      final message = e.toString();
      final permanent = message.contains('permission-denied') ||
          message.contains('invalid-argument');
      await _store.upsert(
        inFlight.copyWith(
          state: permanent
              ? PendingOperationState.failedPermanent
              : PendingOperationState.failedRetryable,
          lastError: message,
        ),
      );
      if (!permanent) {
        await Future<void>.delayed(
          Duration(milliseconds: min(30000, 1000 * pow(2, inFlight.attemptCount).toInt())),
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
    final repo = AssistanceRequestRepositoryImpl(_firestore);
    await repo.acknowledgeRequest(
      requestId: op.payload['requestId']!,
      barangay: op.payload['barangay']!,
      barangayStaffUid: op.ownerUid,
    );
    await _store.upsert(
      op.copyWith(
        state: PendingOperationState.submittedConfirmed,
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
      if (e.code == 'failed-precondition' &&
          (e.message ?? '').contains('already exists')) {
        await _store.upsert(
          op.copyWith(
            state: PendingOperationState.conflict,
            lastError: 'Referral already exists on server.',
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
