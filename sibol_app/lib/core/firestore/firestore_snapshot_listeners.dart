import 'package:cloud_firestore/cloud_firestore.dart';

/// Firestore listeners that drive cache/sync UX must receive metadata-only updates
/// (e.g. [SnapshotMetadata.isFromCache] becoming false without document changes).
abstract final class FirestoreSnapshotListeners {
  static const bool includeMetadataChanges = true;
}

extension DocumentReferenceCacheMetadataSnapshots on DocumentReference<Map<String, dynamic>> {
  Stream<DocumentSnapshot<Map<String, dynamic>>> snapshotsWithCacheMetadata() {
    return snapshots(includeMetadataChanges: FirestoreSnapshotListeners.includeMetadataChanges);
  }
}

extension QueryCacheMetadataSnapshots on Query<Map<String, dynamic>> {
  Stream<QuerySnapshot<Map<String, dynamic>>> snapshotsWithCacheMetadata() {
    return snapshots(includeMetadataChanges: FirestoreSnapshotListeners.includeMetadataChanges);
  }
}
