import 'package:sibol_app/features/cases/domain/entities/follow_up.dart';

FollowUp sampleFollowUp({
  String followUpId = 'follow-up-001',
  String caseId = 'demo-case-001',
  DateTime? scheduledAt,
  FollowUpStatus status = FollowUpStatus.scheduled,
  String notes = 'Fictional follow-up note.',
}) {
  final scheduled = scheduledAt ?? DateTime(2026, 4, 1, 10);
  return FollowUp(
    followUpId: followUpId,
    caseId: caseId,
    scheduledAt: scheduled,
    completedAt: status == FollowUpStatus.completed
        ? scheduled.add(const Duration(hours: 1))
        : null,
    status: status,
    notes: notes,
  );
}
