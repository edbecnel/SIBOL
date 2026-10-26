import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:sibol_app/core/firestore/local_firestore_write.dart';

void main() {
  test('commitWriteLocalFirst completes when write times out but cache confirms',
      () async {
    await commitWriteLocalFirst(
      write: Future<void>.delayed(const Duration(days: 1)),
      isPersistedLocally: () async => true,
      timeout: const Duration(milliseconds: 10),
    );
  });

  test('commitWriteLocalFirst throws when write fails and cache empty', () async {
    await expectLater(
      commitWriteLocalFirst(
        write: Future<void>.error(Exception('permission-denied')),
        isPersistedLocally: () async => false,
        timeout: const Duration(milliseconds: 10),
      ),
      throwsA(isA<LocalFirestoreWriteException>()),
    );
  });

  test('commitWriteLocalFirst succeeds when write completes quickly', () async {
    await commitWriteLocalFirst(
      write: Future<void>.value(),
      isPersistedLocally: () async => true,
    );
  });
}
