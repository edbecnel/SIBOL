enum CaseStatus {
  active('active'),
  followUpScheduled('followUpScheduled'),
  followUpCompleted('followUpCompleted'),
  closed('closed');

  const CaseStatus(this.firestoreValue);

  final String firestoreValue;

  static CaseStatus? fromFirestore(String? value) {
    if (value == null) return null;
    for (final status in CaseStatus.values) {
      if (status.firestoreValue == value) return status;
    }
    return null;
  }
}
