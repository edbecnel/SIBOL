import 'package:flutter_test/flutter_test.dart';
import 'package:sibol_app/features/coordination/domain/referral_summary_validation.dart';

void main() {
  group('ReferralSummaryValidation', () {
    test('accepts summary within bounds', () {
      expect(
        ReferralSummaryValidation.validate('1234567890'),
        isNull,
      );
    });

    test('rejects short summary', () {
      expect(
        ReferralSummaryValidation.validate('short'),
        isNotNull,
      );
    });

    test('rejects empty summary', () {
      expect(ReferralSummaryValidation.validate(''), isNotNull);
      expect(ReferralSummaryValidation.validate(null), isNotNull);
    });

    test('rejects over max length', () {
      expect(
        ReferralSummaryValidation.validate('a' * 2001),
        isNotNull,
      );
    });
  });
}
