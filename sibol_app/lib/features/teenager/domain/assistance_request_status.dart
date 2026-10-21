enum AssistanceRequestStatus {
  submitted('submitted', 'Submitted'),
  acknowledged('acknowledged', 'Acknowledged');

  const AssistanceRequestStatus(this.firestoreValue, this.label);

  final String firestoreValue;
  final String label;

  static AssistanceRequestStatus? fromFirestore(String? value) {
    if (value == null) return null;
    for (final s in AssistanceRequestStatus.values) {
      if (s.firestoreValue == value) return s;
    }
    return null;
  }
}
