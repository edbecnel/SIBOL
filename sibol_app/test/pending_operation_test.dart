import 'package:flutter_test/flutter_test.dart';
import 'package:sibol_app/features/offline/domain/pending_operation.dart';

void main() {
  test('pending operation round-trips json', () {
    final op = PendingOperation(
      operationId: 'op-1',
      ownerUid: 'teen-1',
      kind: PendingOperationKind.teenAssistanceSubmit,
      state: PendingOperationState.waitingToSubmit,
      createdAt: DateTime.utc(2026, 1, 1),
      payload: {'category': 'generalSupport', 'description': 'demo text here'},
      attemptCount: 2,
      lastError: 'network',
    );
    final restored = PendingOperation.fromJson(op.toJson());
    expect(restored.operationId, op.operationId);
    expect(restored.kind, op.kind);
    expect(restored.state, op.state);
    expect(restored.payload['category'], 'generalSupport');
    expect(restored.attemptCount, 2);
  });
}
