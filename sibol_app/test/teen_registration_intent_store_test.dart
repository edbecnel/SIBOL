import 'package:flutter_test/flutter_test.dart';
import 'package:sibol_app/features/teen_registration/data/teen_registration_intent_store.dart';
import 'support/fake_teen_registration_intent_store.dart';

void main() {
  test('fake intent store tracks in-progress flag', () async {
    final TeenRegistrationIntentStore store = FakeTeenRegistrationIntentStore();
    expect(await store.read(), isFalse);
    await store.setInProgress(true);
    expect(await store.read(), isTrue);
    await store.setInProgress(false);
    expect(await store.read(), isFalse);
  });
}
