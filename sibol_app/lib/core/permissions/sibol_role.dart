enum SibolRole {
  teen('teen'),
  barangay('barangay'),
  moph('moph');

  const SibolRole(this.firestoreValue);

  final String firestoreValue;

  static SibolRole? fromFirestore(String? value) {
    if (value == null) return null;
    for (final role in SibolRole.values) {
      if (role.firestoreValue == value) return role;
    }
    return null;
  }

  String get displayLabel {
    switch (this) {
      case SibolRole.teen:
        return 'Teenager';
      case SibolRole.barangay:
        return 'Barangay health personnel';
      case SibolRole.moph:
        return 'MOPH';
    }
  }
}
