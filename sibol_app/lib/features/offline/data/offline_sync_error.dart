import 'package:cloud_functions/cloud_functions.dart';
import 'package:sibol_app/features/offline/domain/pending_operation.dart';

class OfflineSyncFailure {
  const OfflineSyncFailure({
    required this.state,
    required this.message,
  });

  final PendingOperationState state;
  final String message;
}

OfflineSyncFailure classifySyncFailure(Object error) {
  final message = error.toString();
  if (error is FirebaseFunctionsException) {
    if (error.code == 'permission-denied' ||
        error.code == 'unauthenticated' ||
        error.code == 'invalid-argument') {
      return OfflineSyncFailure(
        state: PendingOperationState.failedPermanent,
        message: error.message ?? message,
      );
    }
    if (error.code == 'failed-precondition' &&
        (error.message ?? '').contains('acknowledgment-conflict')) {
      return OfflineSyncFailure(
        state: PendingOperationState.conflict,
        message: error.message ?? message,
      );
    }
    if (error.code == 'failed-precondition' &&
        (error.message ?? '').contains('already exists')) {
      return OfflineSyncFailure(
        state: PendingOperationState.conflict,
        message: error.message ?? message,
      );
    }
  }
  if (message.contains('permission-denied') ||
      message.contains('invalid-argument')) {
    return OfflineSyncFailure(
      state: PendingOperationState.failedPermanent,
      message: message,
    );
  }
  return OfflineSyncFailure(
    state: PendingOperationState.failedRetryable,
    message: message,
  );
}
