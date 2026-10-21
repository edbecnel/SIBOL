enum AssistanceRequestCategory {
  generalSupport('generalSupport', 'General support (demo)'),
  healthInformation('healthInformation', 'Health information (demo)'),
  counselingReferral('counselingReferral', 'Counseling referral (demo)'),
  barangayServices('barangayServices', 'Barangay services (demo)');

  const AssistanceRequestCategory(this.firestoreValue, this.label);

  final String firestoreValue;
  final String label;

  static AssistanceRequestCategory? fromFirestore(String? value) {
    if (value == null) return null;
    for (final c in AssistanceRequestCategory.values) {
      if (c.firestoreValue == value) return c;
    }
    return null;
  }
}
