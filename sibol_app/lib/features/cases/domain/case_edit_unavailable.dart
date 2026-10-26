/// Recoverable failure when a case cannot be loaded for editing offline.
class CaseEditUnavailable implements Exception {
  CaseEditUnavailable(this.message);

  final String message;

  static CaseEditUnavailable missingLocally(String caseId) {
    return CaseEditUnavailable(
      'This case is not available on this device ($caseId). '
      'Open it once while online, or go back and try again when connected.',
    );
  }

  @override
  String toString() => message;
}
