import 'package:flutter_test/flutter_test.dart';
import 'package:sibol_app/features/cases/data/models/follow_up_model.dart';
import 'package:sibol_app/features/cases/domain/entities/follow_up.dart';

void main() {
  test('FollowUpModel round-trips create payload fields', () {
    final scheduled = DateTime.utc(2026, 3, 1, 10);
    final entity = FollowUp(
      followUpId: 'fu-1',
      caseId: 'case-1',
      scheduledAt: scheduled,
      status: FollowUpStatus.scheduled,
      notes: 'Check-in',
    );
    final model = FollowUpModel.fromEntity(entity);
    final map = model.toFirestoreCreate();
    expect(map['caseId'], 'case-1');
    expect(map['status'], 'scheduled');
    expect(map['notes'], 'Check-in');
  });
}
