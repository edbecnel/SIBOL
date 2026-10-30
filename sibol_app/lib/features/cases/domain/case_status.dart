enum CaseStatus {
  open('open'),
  inProgress('inProgress'),
  resolved('resolved'),
  closed('closed'),
  active('active'),
  followUpScheduled('followUpScheduled'),
  followUpCompleted('followUpCompleted');

  const CaseStatus(this.firestoreValue);

  final String firestoreValue;

  static CaseStatus? fromFirestore(String? value) {
    if (value == null) return null;
    for (final status in CaseStatus.values) {
      if (status.firestoreValue == value) return status;
    }
    return null;
  }

  /// Canonical lifecycle label for assistance-linked cases.
  CaseStatus get lifecycleCanonical {
    switch (this) {
      case CaseStatus.active:
        return CaseStatus.open;
      case CaseStatus.followUpScheduled:
      case CaseStatus.followUpCompleted:
        return CaseStatus.inProgress;
      default:
        return this;
    }
  }

  bool get isAssistanceLifecycleManaged =>
      this == open ||
      this == inProgress ||
      this == resolved ||
      this == closed;
}
