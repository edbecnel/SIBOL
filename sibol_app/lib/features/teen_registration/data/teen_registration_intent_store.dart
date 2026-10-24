import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Local UX flag only: user entered authorized Teen self-registration.
/// Does not grant roles; [regRegisterTeenAccount] remains authoritative.
class TeenRegistrationIntentStore {
  TeenRegistrationIntentStore(this._storage);

  static const _key = 'sibol.teen_self_registration_in_progress.v1';

  final FlutterSecureStorage _storage;

  Future<bool> read() async {
    final raw = await _storage.read(key: _key);
    return raw == 'true';
  }

  Future<void> setInProgress(bool inProgress) async {
    if (inProgress) {
      await _storage.write(key: _key, value: 'true');
    } else {
      await _storage.delete(key: _key);
    }
  }
}
