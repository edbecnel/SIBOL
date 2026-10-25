/// Firestore query snapshot with client cache metadata for operator UX.
class FirestoreListSnapshot<T> {
  const FirestoreListSnapshot({
    required this.items,
    required this.isFromCache,
    this.hasPendingWrites = false,
  });

  final List<T> items;
  final bool isFromCache;
  final bool hasPendingWrites;
}
