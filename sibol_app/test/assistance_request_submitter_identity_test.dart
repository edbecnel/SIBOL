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

  test('shows trimmed cached values when present', () {
    expect(assistanceSubmitterDisplayLabel('  Maria  '), 'Maria');
    expect(
      assistanceSubmitterEmailLabel('teen.demo@sibol.local'),
      'teen.demo@sibol.local',
    );
  });
}
