import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:sibol_app/features/teen_registration/data/teen_registration_intent_store.dart';

class FakeTeenRegistrationIntentStore extends TeenRegistrationIntentStore {
  FakeTeenRegistrationIntentStore() : super(const FlutterSecureStorage());

  bool _inProgress = false;

  @override
  Future<bool> read() async => _inProgress;

  @override
  Future<void> setInProgress(bool inProgress) async {
    _inProgress = inProgress;
  }
}
