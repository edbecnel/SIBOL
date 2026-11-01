import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sibol_app/core/providers/firebase_providers.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:sibol_app/features/offline/data/offline_sync_service.dart';
import 'package:sibol_app/features/offline/data/pending_operation_store.dart';
import 'package:sibol_app/features/offline/domain/pending_operation.dart';

final pendingOperationStoreProvider = Provider<PendingOperationStore>((ref) {
  return PendingOperationStore(
    const FlutterSecureStorage(),
    resolveFirebaseProjectId: () {
      if (Firebase.apps.isEmpty) {
        throw StateError('Firebase must initialize before offline queue access.');
      }
      return Firebase.app().options.projectId;
    },
  );
});

final offlineSyncServiceProvider = Provider<OfflineSyncService>((ref) {
  return OfflineSyncService(
    store: ref.watch(pendingOperationStoreProvider),
    functions: ref.watch(firebaseFunctionsProvider),
    firestore: ref.watch(firestoreProvider),
    auth: ref.watch(firebaseAuthProvider),
  );
});

final pendingOperationsProvider =
    FutureProvider.family<List<PendingOperation>, String>((ref, uid) async {
  return ref.watch(offlineSyncServiceProvider).pendingForUser(uid);
});
