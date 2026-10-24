import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

/// Maps registry document snapshots to whether a referral exists.
bool mapRegistrySnapshotToReferralExists(
  DocumentSnapshot<Map<String, dynamic>> snapshot,
) =>
    snapshot.exists;

/// Live rules (pre–registry-read fix) deny `get`/listen when the registry
/// document is missing because `resource.data` is evaluated. Treat that as
/// no referral so Barangay can still open the referral action; the callable
/// enforces duplicates.
bool isMissingRegistryDocumentPermissionDenied(Object error) {
  return error is FirebaseException && error.code == 'permission-denied';
}

Stream<bool> mapRegistrySnapshotsToReferralExists(
  Stream<DocumentSnapshot<Map<String, dynamic>>> snapshots,
) {
  return snapshots.transform(
    StreamTransformer.fromHandlers(
      handleData: (snap, sink) {
        sink.add(mapRegistrySnapshotToReferralExists(snap));
      },
      handleError: (error, stackTrace, sink) {
        if (isMissingRegistryDocumentPermissionDenied(error)) {
          sink.add(false);
          return;
        }
        sink.addError(error, stackTrace);
      },
    ),
  );
}
