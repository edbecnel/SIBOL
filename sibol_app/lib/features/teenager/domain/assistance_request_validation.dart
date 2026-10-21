import 'package:sibol_app/features/teenager/domain/assistance_request_category.dart';

class AssistanceRequestValidation {
  static const int minDescriptionLength = 10;
  static const int maxDescriptionLength = 500;

  static String? validateCategory(AssistanceRequestCategory? category) {
    if (category == null) return 'Please select a request category.';
    return null;
  }

  static String? validateDescription(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return 'Description is required.';
    if (trimmed.length < minDescriptionLength) {
      return 'Description must be at least $minDescriptionLength characters.';
    }
    if (trimmed.length > maxDescriptionLength) {
      return 'Description must be at most $maxDescriptionLength characters.';
    }
    return null;
  }
}
