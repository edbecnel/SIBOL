import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:sibol_app/features/teen_registration/data/teen_registration_intent_store.dart';

final teenRegistrationIntentStoreProvider = Provider<TeenRegistrationIntentStore>((ref) {
  return TeenRegistrationIntentStore(const FlutterSecureStorage());
});

class TeenRegistrationIntentNotifier extends Notifier<bool> {
  @override
  bool build() {
    _hydrate();
    return false;
  }

  Future<void> _hydrate() async {
    final value = await ref.read(teenRegistrationIntentStoreProvider).read();
    if (state != value) state = value;
  }

  Future<void> markInProgress() async {
    await ref.read(teenRegistrationIntentStoreProvider).setInProgress(true);
    state = true;
  }

  Future<void> clear() async {
    await ref.read(teenRegistrationIntentStoreProvider).setInProgress(false);
    state = false;
  }
}

final teenRegistrationIntentProvider =
    NotifierProvider<TeenRegistrationIntentNotifier, bool>(
  TeenRegistrationIntentNotifier.new,
);
