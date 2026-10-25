import 'package:flutter_test/flutter_test.dart';
import 'package:sibol_app/features/cases/domain/follow_up_sync_state.dart';

void main() {
  test('pending when hasPendingWrites is true', () {
    expect(
      FollowUpSyncState.awaitingServerConfirmation(
        hasPendingWrites: true,
        createdAtPresentInDocument: true,
        createdByUid: 'uid',
      ),
      isTrue,
    );
  });

  test('pending after restart when server createdAt not present', () {
    expect(
      FollowUpSyncState.awaitingServerConfirmation(
        hasPendingWrites: false,
        createdAtPresentInDocument: false,
        createdByUid: 'barangay-staff',
      ),
      isTrue,
    );
  });

  test('not pending for legacy rows without createdByUid', () {
    expect(
      FollowUpSyncState.awaitingServerConfirmation(
        hasPendingWrites: false,
        createdAtPresentInDocument: false,
        createdByUid: null,
      ),
      isFalse,
    );
  });

  test('confirmed when createdAt present and no pending writes', () {
    expect(
      FollowUpSyncState.awaitingServerConfirmation(
        hasPendingWrites: false,
        createdAtPresentInDocument: true,
        createdByUid: 'barangay-staff',
      ),
      isFalse,
    );
  });
}
