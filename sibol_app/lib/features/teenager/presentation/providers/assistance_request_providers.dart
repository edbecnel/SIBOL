import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sibol_app/core/providers/firebase_providers.dart';
import 'package:sibol_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:sibol_app/core/domain/firestore_list_snapshot.dart';
import 'package:sibol_app/features/teenager/domain/entities/assistance_request.dart';

final myAssistanceRequestsProvider =
    StreamProvider<FirestoreListSnapshot<AssistanceRequest>>((ref) {
  final uid = ref.watch(authStateChangesProvider).value?.uid;
  if (uid == null) return const Stream.empty();
  return ref.watch(assistanceRequestRepositoryProvider).watchMyRequests(uid);
});

final assistanceRequestDetailProvider =
    StreamProvider.family<AssistanceRequest?, String>((ref, requestId) {
  final uid = ref.watch(authStateChangesProvider).value?.uid;
  if (uid == null) return const Stream.empty();
  return ref
      .watch(assistanceRequestRepositoryProvider)
      .watchRequest(requestId, uid);
});
