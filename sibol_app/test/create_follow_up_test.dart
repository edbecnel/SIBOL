import 'package:flutter_test/flutter_test.dart';
import 'package:sibol_app/features/cases/domain/entities/follow_up.dart';
import 'support/fake_case_repository.dart';
import 'support/sample_case_records.dart';

void main() {
  test('createFollowUp stores case association and staff uid', () async {
    final record = sampleCaseRecord();
    final repo = FakeCaseRepository(cases: [record]);
    final id = await repo.createFollowUp(
      followUp: FollowUp(
        followUpId: '',
        caseId: record.caseId,
        scheduledAt: DateTime.utc(2026, 4, 2),
        completedAt: DateTime.utc(2026, 4, 2),
        status: FollowUpStatus.completed,
        notes: 'Counselling session documented.',
      ),
      createdByUid: 'barangay-staff-1',
    );
    expect(id, startsWith('fu-'));
  });

  test('createFollowUp rejects missing notes', () async {
    final repo = FakeCaseRepository();
    expect(
      () => repo.createFollowUp(
        followUp: FollowUp(
          followUpId: '',
          caseId: 'case-1',
          scheduledAt: DateTime.now(),
          status: FollowUpStatus.completed,
          notes: '  ',
        ),
        createdByUid: 'staff',
      ),
      throwsFormatException,
    );
  });
}
