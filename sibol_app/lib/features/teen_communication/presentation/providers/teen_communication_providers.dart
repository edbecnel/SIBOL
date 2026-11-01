import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sibol_app/core/constants/firestore_paths.dart';
import 'package:sibol_app/core/providers/firebase_providers.dart';
import 'package:sibol_app/features/teen_communication/data/teen_communication_api.dart';

final teenCommunicationApiProvider = Provider<TeenCommunicationApi>((ref) {
  return TeenCommunicationApi(ref.watch(firebaseFunctionsProvider));
});

class TeenAssistanceMessage {
  const TeenAssistanceMessage({
    required this.messageId,
    required this.displayText,
    required this.createdAt,
    required this.publisherRole,
    required this.templateCode,
  });

  final String messageId;
  final String displayText;
  final DateTime createdAt;
  final String publisherRole;
  final String templateCode;

  factory TeenAssistanceMessage.fromFirestore(
    String id,
    Map<String, dynamic> data,
  ) {
    final ts = data['createdAt'];
    DateTime createdAt = DateTime.now();
    if (ts is Timestamp) {
      createdAt = ts.toDate();
    }
    return TeenAssistanceMessage(
      messageId: id,
      displayText: data['displayText'] as String? ?? '',
      createdAt: createdAt,
      publisherRole: data['publisherRole'] as String? ?? 'system',
      templateCode: data['templateCode'] as String? ?? '',
    );
  }

  String get sourceLabel {
    switch (publisherRole) {
      case 'barangay':
        return 'Barangay update';
      case 'system':
        return 'SIBOL notification';
      default:
        return 'Update';
    }
  }
}

final teenAssistanceMessagesProvider =
    StreamProvider.family<List<TeenAssistanceMessage>, String>(
  (ref, assistanceRequestId) {
    return ref.watch(firestoreProvider).collection(
          FirestorePaths.teenAssistanceCommunications,
        ).doc(assistanceRequestId).collection('messages').orderBy(
          'createdAt',
          descending: false,
        ).snapshots().map(
          (snap) => snap.docs
              .map(
                (d) => TeenAssistanceMessage.fromFirestore(d.id, d.data()),
              )
              .toList(),
        );
  },
);

final barangayAssistanceMessagesProvider =
    teenAssistanceMessagesProvider;
