import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sibol_app/features/offline/data/offline_sync_error.dart';
import 'package:sibol_app/features/offline/domain/pending_operation.dart';

void main() {
  test('maps acknowledgment conflict to terminal conflict state', () {
    final failure = classifySyncFailure(
      FirebaseFunctionsException(
        code: 'failed-precondition',
        message: 'acknowledgment-conflict: duplicate acknowledgment operation.',
      ),
    );
    expect(failure.state, PendingOperationState.conflict);
  });

  test('maps permission-denied to failedPermanent', () {
    final failure = classifySyncFailure(
      FirebaseFunctionsException(
        code: 'permission-denied',
        message: 'Not authorized.',
      ),
    );
    expect(failure.state, PendingOperationState.failedPermanent);
  });

  test('maps transient errors to retryable', () {
    final failure = classifySyncFailure(Exception('network timeout'));
    expect(failure.state, PendingOperationState.failedRetryable);
  });
}
