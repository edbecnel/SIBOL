import 'package:flutter_test/flutter_test.dart';
import 'package:sibol_app/features/offline/domain/offline_sync_summary.dart';

void main() {
  test('offline summary explains connectivity', () {
    const summary = OfflineSyncSummary(
      offline: true,
      attempted: 0,
      confirmed: 0,
      stillPending: 2,
    );
    expect(summary.userMessage, contains('offline'));
  });

  test('success summary reports confirmed count', () {
    const summary = OfflineSyncSummary(
      offline: false,
      attempted: 1,
      confirmed: 1,
      stillPending: 0,
    );
    expect(summary.userMessage, contains('Synced 1'));
  });
}
