/// Derives honest follow-up synchronization UX from Firestore metadata and fields.
///
/// After an app restart, Firestore may report [hasPendingWrites] as false for
/// documents that still have an unacknowledged [createdAt] server timestamp.
class FollowUpSyncState {
  static bool awaitingServerConfirmation({
    required bool hasPendingWrites,
    required bool createdAtPresentInDocument,
    required String? createdByUid,
  }) {
    if (hasPendingWrites) return true;
    if (createdByUid != null &&
        createdByUid.isNotEmpty &&
        !createdAtPresentInDocument) {
      return true;
    }
    return false;
  }
}
