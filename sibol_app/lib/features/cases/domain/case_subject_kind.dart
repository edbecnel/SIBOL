/// How the case subject is associated with SIBOL identity.
enum CaseSubjectKind {
  registered('registered'),
  unregistered('unregistered');

  const CaseSubjectKind(this.firestoreValue);

  final String firestoreValue;

  static CaseSubjectKind? fromFirestore(String? value) {
    if (value == null) return null;
    for (final kind in CaseSubjectKind.values) {
      if (kind.firestoreValue == value) return kind;
    }
    return null;
  }

  /// Legacy documents without [subjectKind] are treated as unregistered manual records.
  static CaseSubjectKind resolveStored(String? value) {
    return fromFirestore(value) ?? CaseSubjectKind.unregistered;
  }
}
