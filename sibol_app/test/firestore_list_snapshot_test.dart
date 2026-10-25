import 'package:flutter_test/flutter_test.dart';
import 'package:sibol_app/core/domain/firestore_list_snapshot.dart';

void main() {
  test('FirestoreListSnapshot exposes cache metadata for UI', () {
    const snap = FirestoreListSnapshot<int>(
      items: [1, 2],
      isFromCache: true,
      hasPendingWrites: false,
    );
    expect(snap.items, [1, 2]);
    expect(snap.isFromCache, isTrue);
    expect(snap.hasPendingWrites, isFalse);
  });
}
