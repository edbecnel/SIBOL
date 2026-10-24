import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sibol_app/features/coordination/data/coordination_registry_referral_probe.dart';

void main() {
  group('mapRegistrySnapshotsToReferralExists', () {
    test('emits true when snapshot exists', () async {
      final stream = mapRegistrySnapshotsToReferralExists(
        Stream.value(_FakeSnapshot(exists: true)),
      );
      expect(await stream.first, isTrue);
    });

    test('emits false when snapshot does not exist', () async {
      final stream = mapRegistrySnapshotsToReferralExists(
        Stream.value(_FakeSnapshot(exists: false)),
      );
      expect(await stream.first, isFalse);
    });

    test('maps permission-denied to false (missing registry doc)', () async {
      final stream = mapRegistrySnapshotsToReferralExists(
        Stream.error(
          FirebaseException(
            plugin: 'cloud_firestore',
            code: 'permission-denied',
          ),
        ),
      );
      expect(await stream.first, isFalse);
    });

    test('rethrows non-permission errors', () async {
      final stream = mapRegistrySnapshotsToReferralExists(
        Stream.error(StateError('network')),
      );
      expect(stream.first, throwsA(isA<StateError>()));
    });
  });
}

class _FakeSnapshot implements DocumentSnapshot<Map<String, dynamic>> {
  _FakeSnapshot({required this.exists});

  @override
  final bool exists;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
