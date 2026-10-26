import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Labels for Barangay assistance request submitter identity (cached snapshot).
class AssistanceRequestSubmitterIdentityLabels {
  static const submittedBy = 'Submitted by';
  static const accountEmail = 'Account email';
  static const unavailable = 'Not available';
  static const resolveFailed =
      'Could not refresh submitter identity. Showing cached data if available.';
}

/// Whether the assistance document still needs a server identity snapshot.
bool assistanceRequestNeedsSubmitterIdentitySnapshot({
  String? submitterDisplayName,
  String? submitterAccountEmail,
}) {
  final name = submitterDisplayName?.trim();
  final email = submitterAccountEmail?.trim();
  return name == null ||
      name.isEmpty ||
      email == null ||
      email.isEmpty;
}

/// Safe diagnostic text for logs (no emails, passwords, or tokens).
String assistanceIdentityResolveLogMessage(Object error) {
  if (error is FirebaseFunctionsException) {
    return 'code=${error.code}';
  }
  if (error is FirebaseAuthException) {
    return 'code=${error.code}';
  }
  return 'type=${error.runtimeType}';
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
