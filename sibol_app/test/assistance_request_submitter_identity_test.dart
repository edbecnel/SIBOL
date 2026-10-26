import 'package:flutter_test/flutter_test.dart';
import 'package:sibol_app/features/teenager/domain/assistance_request_submitter_identity.dart';

void main() {
  test('shows unavailable when cached identity fields are missing', () {
    expect(
      assistanceSubmitterDisplayLabel(null),
      AssistanceRequestSubmitterIdentityLabels.unavailable,
    );
    expect(
      assistanceSubmitterEmailLabel('  '),
      AssistanceRequestSubmitterIdentityLabels.unavailable,
    );
  });

  test('needs snapshot when name or email missing', () {
    expect(
      assistanceRequestNeedsSubmitterIdentitySnapshot(
        submitterDisplayName: 'Teen',
        submitterAccountEmail: null,
      ),
      isTrue,
    );
    expect(
      assistanceRequestNeedsSubmitterIdentitySnapshot(
        submitterDisplayName: 'Teen',
        submitterAccountEmail: 'a@b.c',
      ),
      isFalse,
    );
  });

  test('formats incoming card account email line', () {
    expect(
      assistanceIncomingRequestCardAccountEmailLine('teen.demo@sibol.local'),
      'Account email: teen.demo@sibol.local',
    );
    expect(
      assistanceIncomingRequestCardAccountEmailLine(null),
      'Account email: Not available',
    );
  });

  test('shows trimmed cached values when present', () {
    expect(assistanceSubmitterDisplayLabel('  Maria  '), 'Maria');
    expect(
      assistanceSubmitterEmailLabel('teen.demo@sibol.local'),
      'teen.demo@sibol.local',
    );
  });
}
