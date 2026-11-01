/// Firebase project identity stamped on offline queue entries.
abstract final class OfflineFirebaseEnvironment {
  static const String legacyUnstampedSentinel = '__legacy_unstamped__';

  static String storageKeyPrefix(String firebaseProjectId) =>
      'sibol.pending_ops.v2.$firebaseProjectId';

  static String legacyStorageKeyPrefix() => 'sibol.pending_ops.v1';

  static bool isLegacyUnstamped(String? firebaseProjectId) =>
      firebaseProjectId == null ||
      firebaseProjectId.isEmpty ||
      firebaseProjectId == legacyUnstampedSentinel;
}
