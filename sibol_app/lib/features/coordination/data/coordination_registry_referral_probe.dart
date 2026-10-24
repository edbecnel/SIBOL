import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:sibol_app/config/env_config.dart';

/// Maps registry document snapshots to whether a referral exists.
bool mapRegistrySnapshotToReferralExists(
  DocumentSnapshot<Map<String, dynamic>> snapshot,
) =>
    snapshot.exists;

/// Whether to treat registry `permission-denied` as “no referral yet”.
///
/// **Stage 1 (live):** `false` — required while deployed rules deny reads on
/// missing registry documents.
///
/// **Stage 2:** Set [EnvConfig.coordinationRegistryRulesV2] to `true` after
/// Firestore rules deploy (see
/// `Docs/Development/SIBOL_CASE_COORD_001_REGISTRY_RULES_DEPLOY_READINESS.md`).
bool get useLegacyRegistryAbsenceProbe =>
    !EnvConfig.coordinationRegistryRulesV2;

bool isRegistryPermissionDenied(Object error) {
  return error is FirebaseException && error.code == 'permission-denied';
}

Stream<bool> mapRegistrySnapshotsToReferralExists(
  Stream<DocumentSnapshot<Map<String, dynamic>>> snapshots, {
  bool? legacyAbsenceProbe,
}) {
  final useLegacyProbe = legacyAbsenceProbe ?? useLegacyRegistryAbsenceProbe;
  return snapshots.transform(
    StreamTransformer.fromHandlers(
      handleData: (snap, sink) {
        sink.add(mapRegistrySnapshotToReferralExists(snap));
      },
      handleError: (error, stackTrace, sink) {
        if (useLegacyProbe && isRegistryPermissionDenied(error)) {
          sink.add(false);
          return;
        }
        sink.addError(error, stackTrace);
      },
    ),
  );
}
