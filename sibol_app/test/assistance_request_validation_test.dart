import 'package:flutter_test/flutter_test.dart';
import 'package:sibol_app/features/teenager/domain/assistance_request_category.dart';
import 'package:sibol_app/features/teenager/domain/assistance_request_validation.dart';

void main() {
  group('AssistanceRequestValidation', () {
    test('requires category', () {
      expect(
        AssistanceRequestValidation.validateCategory(null),
        isNotNull,
      );
    });

    test('requires description length', () {
      expect(
        AssistanceRequestValidation.validateDescription('short'),
        isNotNull,
      );
      expect(
        AssistanceRequestValidation.validateDescription(
          'Fictional demo request with enough characters.',
        ),
        isNull,
      );
    });

    test('accepts valid category', () {
      expect(
        AssistanceRequestValidation.validateCategory(
          AssistanceRequestCategory.generalSupport,
        ),
        isNull,
      );
    });
  });
}
