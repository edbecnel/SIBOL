/// Single Firestore document with client cache metadata for operator UX.
class FirestoreDocumentSnapshot<T> {
  const FirestoreDocumentSnapshot({
    required this.data,
    required this.isFromCache,
    this.hasPendingWrites = false,
  });

  final T? data;
  final bool isFromCache;
  final bool hasPendingWrites;
}
