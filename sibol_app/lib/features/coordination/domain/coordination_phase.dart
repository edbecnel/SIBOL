enum CoordinationPhase {
  referred('referred', 'Referred'),
  awaitingBarangay('awaitingBarangay', 'Awaiting barangay'),
  awaitingMoph('awaitingMoph', 'Awaiting MOPH'),
  closed('closed', 'Closed');

  const CoordinationPhase(this.firestoreValue, this.label);

  final String firestoreValue;
  final String label;

  static CoordinationPhase? fromFirestore(String? value) {
    if (value == null) return null;
    for (final p in CoordinationPhase.values) {
      if (p.firestoreValue == value) return p;
    }
    return null;
  }
}
