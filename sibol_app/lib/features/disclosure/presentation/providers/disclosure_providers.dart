import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sibol_app/core/constants/firestore_paths.dart';
import 'package:sibol_app/core/providers/firebase_providers.dart';
import 'package:sibol_app/features/auth/presentation/providers/auth_providers.dart';

class DisclosureAuthorizationView {
  DisclosureAuthorizationView({
    required this.authorizationId,
    required this.assistanceRequestId,
    required this.status,
    required this.requestedCategories,
    required this.authorizedCategories,
    required this.purposeCode,
  });

  final String authorizationId;
  final String assistanceRequestId;
  final String status;
  final List<String> requestedCategories;
  final List<String> authorizedCategories;
  final String purposeCode;

  factory DisclosureAuthorizationView.fromDoc(
    String id,
    Map<String, dynamic> data,
  ) {
    return DisclosureAuthorizationView(
      authorizationId: id,
      assistanceRequestId: data['assistanceRequestId'] as String? ?? '',
      status: data['status'] as String? ?? '',
      requestedCategories: (data['requestedCategories'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      authorizedCategories: (data['authorizedCategories'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      purposeCode: data['purposeCode'] as String? ?? '',
    );
  }
}

final disclosureAuthorizationsForAssistanceProvider = StreamProvider.autoDispose
    .family<List<DisclosureAuthorizationView>, String>((ref, assistanceId) {
  final firestore = ref.watch(firestoreProvider);
  return firestore
      .collection(FirestorePaths.disclosureAuthorizations)
      .where('assistanceRequestId', isEqualTo: assistanceId)
      .snapshots()
      .map(
        (snap) => snap.docs
            .map((d) => DisclosureAuthorizationView.fromDoc(d.id, d.data()))
            .toList(),
      );
});

final teenPendingDisclosureAuthorizationsProvider =
    StreamProvider.autoDispose<List<DisclosureAuthorizationView>>((ref) {
  final uid = ref.watch(authStateChangesProvider).value?.uid;
  if (uid == null) {
    return const Stream.empty();
  }
  final firestore = ref.watch(firestoreProvider);
  return firestore
      .collection(FirestorePaths.disclosureAuthorizations)
      .where('teenUid', isEqualTo: uid)
      .where('status', isEqualTo: 'requested')
      .snapshots()
      .map(
        (snap) => snap.docs
            .map((d) => DisclosureAuthorizationView.fromDoc(d.id, d.data()))
            .toList(),
      );
});

final teenCoordinationLinkForAssistanceProvider = StreamProvider.autoDispose
    .family<Map<String, dynamic>?, String>((ref, assistanceId) {
  final uid = ref.watch(authStateChangesProvider).value?.uid;
  if (uid == null) {
    return const Stream.empty();
  }
  final firestore = ref.watch(firestoreProvider);
  return firestore
      .collection(FirestorePaths.teenCoordinationLinks)
      .doc(uid)
      .collection('links')
      .doc(assistanceId)
      .snapshots()
      .map((snap) => snap.data());
});
