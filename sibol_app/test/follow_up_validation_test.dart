import 'package:flutter_test/flutter_test.dart';
import 'package:sibol_app/features/cases/domain/follow_up_validation.dart';

void main() {
  test('rejects empty follow-up notes', () {
    expect(FollowUpValidation.validateNotes(''), isNotNull);
    expect(FollowUpValidation.validateNotes('  '), isNotNull);
  });

  test('accepts meaningful notes', () {
    expect(
      FollowUpValidation.validateNotes('Home visit completed; teen referred.'),
      isNull,
    );
  });
}
