/// Labels for Barangay assistance request submitter identity (cached snapshot).
class AssistanceRequestSubmitterIdentityLabels {
  static const submittedBy = 'Submitted by';
  static const accountEmail = 'Account email';
  static const unavailable = 'Not available';
}

String assistanceSubmitterDisplayLabel(String? cachedDisplayName) {
  final trimmed = cachedDisplayName?.trim();
  if (trimmed == null || trimmed.isEmpty) {
    return AssistanceRequestSubmitterIdentityLabels.unavailable;
  }
  return trimmed;
}

String assistanceSubmitterEmailLabel(String? cachedAccountEmail) {
  final trimmed = cachedAccountEmail?.trim();
  if (trimmed == null || trimmed.isEmpty) {
    return AssistanceRequestSubmitterIdentityLabels.unavailable;
  }
  return trimmed;
}
