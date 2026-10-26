/// Whether a case is an incomplete draft or operationally complete.
enum CaseCompleteness {
  draft('draft'),
  active('active'),
  /// Age-only legacy QA/demo records without DOB or contact (still readable).
  legacyIncomplete('legacyIncomplete');

  const CaseCompleteness(this.firestoreValue);

  final String firestoreValue;

  static CaseCompleteness? fromFirestore(String? value) {
    if (value == null) return null;
    for (final c in CaseCompleteness.values) {
      if (c.firestoreValue == value) return c;
    }
    return null;
  }

  static CaseCompleteness inferFromRecord({
    required String? stored,
    required bool hasDateOfBirth,
    required bool hasContactMethod,
    required bool hasFullName,
    required bool isLegacyAgeOnlyDocument,
  }) {
    final parsed = fromFirestore(stored);
    if (parsed != null) return parsed;
    if (isLegacyAgeOnlyDocument) return CaseCompleteness.legacyIncomplete;
    if (hasFullName &&
        hasDateOfBirth &&
        hasContactMethod &&
        stored == null) {
      return CaseCompleteness.active;
    }
    return CaseCompleteness.legacyIncomplete;
  }

  bool get isOperationallyComplete =>
      this == CaseCompleteness.active || this == CaseCompleteness.legacyIncomplete;
}
