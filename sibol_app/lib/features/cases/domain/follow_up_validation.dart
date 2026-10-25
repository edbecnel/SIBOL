class FollowUpValidation {
  static const int minNotesLength = 3;
  static const int maxNotesLength = 2000;

  static String? validateNotes(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return 'Describe the action taken or observation before saving.';
    }
    if (trimmed.length < minNotesLength) {
      return 'Entry is too short — add a bit more detail.';
    }
    if (trimmed.length > maxNotesLength) {
      return 'Entry must be at most $maxNotesLength characters.';
    }
    return null;
  }
}
