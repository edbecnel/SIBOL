import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

/// Thrown when a write could not be confirmed in the local Firestore cache.
class LocalFirestoreWriteException implements Exception {
  LocalFirestoreWriteException(this.message, {this.cause});

  final String message;
  final Object? cause;

  @override
  String toString() => message;
}

/// Waits for [write] up to [timeout], then confirms persistence via [isPersistedLocally].
typedef LocalPersistenceCheck = Future<bool> Function();

Future<void> commitWriteLocalFirst({
  required Future<void> write,
  required LocalPersistenceCheck isPersistedLocally,
  Duration timeout = const Duration(seconds: 5),
}) async {
  Object? writeError;
  StackTrace? writeStack;
  try {
    await write.timeout(timeout);
    if (await isPersistedLocally()) return;
  } on TimeoutException {
    if (await isPersistedLocally()) return;
  } catch (e, st) {
    writeError = e;
    writeStack = st;
    if (await isPersistedLocally()) return;
  }

  final message = writeError != null
      ? 'Could not save on this device. ${writeError.toString()}'
      : 'Could not save on this device. Check storage and try again.';
  Error.throwWithStackTrace(
    LocalFirestoreWriteException(message, cause: writeError),
    writeStack ?? StackTrace.current,
  );
}

Future<bool> documentExistsInCache(DocumentReference<Map<String, dynamic>> ref) async {
  try {
    final snap = await ref.get(const GetOptions(source: Source.cache));
    return snap.exists;
  } on FirebaseException {
    return false;
  }
}
