import 'package:flutter_test/flutter_test.dart';
import 'package:sibol_app/features/cases/domain/entities/follow_up.dart';
import 'package:sibol_app/features/cases/domain/follow_up_staff_identity.dart';

void main() {
  test('prefers display name and email over uid', () {
    final followUp = FollowUp(
      followUpId: 'fu-1',
      caseId: 'case-1',
      scheduledAt: DateTime.utc(2026, 1, 1),
      status: FollowUpStatus.completed,
      notes: 'Note',
      createdByUid: 'uid-legacy',
      createdByDisplayName: 'Demo BNS',
      createdByStaffEmail: 'bns.fictional@sibol.local',
    );
    expect(
      FollowUpStaffIdentity.recordedByLine(followUp),
      'Recorded by Demo BNS (bns.fictional@sibol.local)',
    );
  });

  test('falls back to uid when snapshots missing', () {
    final followUp = FollowUp(
      followUpId: 'fu-2',
      caseId: 'case-1',
      scheduledAt: DateTime.utc(2026, 1, 1),
      status: FollowUpStatus.completed,
      notes: 'Note',
      createdByUid: 'staff-uid-123',
    );
    expect(
      FollowUpStaffIdentity.recordedByLine(followUp),
      'Recorded by staff (staff-uid-123)',
    );
  });
}
