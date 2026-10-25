import 'package:equatable/equatable.dart';

enum FollowUpStatus {
  scheduled('scheduled'),
  completed('completed'),
  cancelled('cancelled');

  const FollowUpStatus(this.firestoreValue);

  final String firestoreValue;

  static FollowUpStatus? fromFirestore(String? value) {
    if (value == null) return null;
    for (final status in FollowUpStatus.values) {
      if (status.firestoreValue == value) return status;
    }
    return null;
  }
}

class FollowUp extends Equatable {
  const FollowUp({
    required this.followUpId,
    required this.caseId,
    required this.scheduledAt,
    this.completedAt,
    required this.status,
    this.notes = '',
    this.createdAt,
    this.createdByUid,
  });

  final String followUpId;
  final String caseId;
  final DateTime scheduledAt;
  final DateTime? completedAt;
  final FollowUpStatus status;
  final String notes;
  final DateTime? createdAt;
  final String? createdByUid;

  @override
  List<Object?> get props => [
        followUpId,
        caseId,
        scheduledAt,
        completedAt,
        status,
        notes,
        createdAt,
        createdByUid,
      ];
}
