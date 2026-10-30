enum CoordinationStatus {
  submitted('submitted', 'Submitted'),
  received('received', 'Received'),
  acceptedForCoordination(
    'acceptedForCoordination',
    'Accepted for coordination',
  ),
  additionalInformationRequested(
    'additionalInformationRequested',
    'Additional information requested',
  ),
  informationProvided('informationProvided', 'Information provided'),
  unableToAccommodate('unableToAccommodate', 'Unable to accommodate'),
  coordinationCompleted(
    'coordinationCompleted',
    'Coordination completed',
  );

  const CoordinationStatus(this.firestoreValue, this.label);

  final String firestoreValue;
  final String label;

  static CoordinationStatus? fromFirestore(String? value) {
    if (value == null) return null;
    for (final s in CoordinationStatus.values) {
      if (s.firestoreValue == value) return s;
    }
    return null;
  }

  bool get isTerminal =>
      this == unableToAccommodate || this == coordinationCompleted;
}
