import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:sibol_app/features/offline/data/offline_sync_service.dart';
import 'package:sibol_app/features/offline/data/pending_operation_store.dart';
import 'package:sibol_app/features/offline/domain/pending_operation.dart';

final pendingOperationStoreProvider = Provider<PendingOperationStore>((ref) {
  return PendingOperationStore(const FlutterSecureStorage());
});

final offlineSyncServiceProvider = Provider<OfflineSyncService>((ref) {
  return OfflineSyncService(
    store: ref.watch(pendingOperationStoreProvider),
    functions: FirebaseFunctions.instance,
    firestore: FirebaseFirestore.instance,
  );
});

final pendingOperationsProvider =
    FutureProvider.family<List<PendingOperation>, String>((ref, uid) async {
  return ref.watch(offlineSyncServiceProvider).pendingForUser(uid);
});
