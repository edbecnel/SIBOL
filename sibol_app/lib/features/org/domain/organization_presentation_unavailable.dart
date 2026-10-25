/// User-facing failure when organization directory presentation cannot be resolved
/// and no trusted offline cache exists. Not an authorization signal.
class OrganizationPresentationUnavailable implements Exception {
  OrganizationPresentationUnavailable(this.message);

  final String message;

  static const String onlineInitializationRequired =
      'Organization details are not available offline. '
      'Connect to the internet and open this screen once while signed in '
      'so your device can save the organization name from the directory.';

  static OrganizationPresentationUnavailable missingTrustedCache([String? orgId]) {
    final suffix = orgId != null && orgId.isNotEmpty ? ' ($orgId)' : '';
    return OrganizationPresentationUnavailable(
      '$onlineInitializationRequired$suffix',
    );
  }

  @override
  String toString() => message;
}
