class OfflineSyncSummary {
  const OfflineSyncSummary({
    required this.offline,
    required this.attempted,
    required this.confirmed,
    required this.stillPending,
    this.lastError,
  });

  final bool offline;
  final int attempted;
  final int confirmed;
  final int stillPending;
  final String? lastError;

  String get userMessage {
    if (offline) {
      return 'Device is offline — connect to Wi‑Fi or mobile data, then retry.';
    }
    if (attempted == 0) {
      return 'No pending actions to sync right now.';
    }
    if (confirmed > 0 && stillPending == 0) {
      return 'Synced $confirmed action(s) with the server.';
    }
    if (confirmed > 0 && stillPending > 0) {
      return 'Synced $confirmed action(s); $stillPending still waiting.';
    }
    if (lastError != null && lastError!.isNotEmpty) {
      return 'Sync did not complete: $lastError';
    }
    return 'Sync finished — $stillPending action(s) still pending.';
  }
}
