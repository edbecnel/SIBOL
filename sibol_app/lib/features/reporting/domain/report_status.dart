/// Client-visible reporting lifecycle (server acceptance is authoritative for MOPH).
enum ReportStatus {
  notSubmitted('notSubmitted'),
  pendingSubmit('pendingSubmit'),
  submitted('submitted'),
  submitFailed('submitFailed');

  const ReportStatus(this.firestoreValue);

  final String firestoreValue;

  static ReportStatus? fromFirestore(String? value) {
    if (value == null) return null;
    for (final status in ReportStatus.values) {
      if (status.firestoreValue == value) return status;
    }
    return null;
  }
}
