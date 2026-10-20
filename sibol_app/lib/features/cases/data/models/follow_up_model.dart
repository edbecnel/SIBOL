import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sibol_app/features/cases/domain/entities/follow_up.dart';

class FollowUpModel {
  FollowUpModel({
    required this.followUpId,
    required this.caseId,
    required this.scheduledAt,
    this.completedAt,
    required this.status,
    required this.notes,
  });

  final String followUpId;
  final String caseId;
  final DateTime scheduledAt;
  final DateTime? completedAt;
  final String status;
  final String notes;

  factory FollowUpModel.fromFirestore(String id, Map<String, dynamic> data) {
    return FollowUpModel(
      followUpId: id,
      caseId: data['caseId'] as String? ?? '',
      scheduledAt: _toDate(data['scheduledAt']),
      completedAt: data['completedAt'] == null
          ? null
          : _toDate(data['completedAt']),
      status: data['status'] as String? ?? 'scheduled',
      notes: data['notes'] as String? ?? '',
    );
  }

  FollowUp toEntity() {
    final parsed = FollowUpStatus.fromFirestore(status);
    if (parsed == null) {
      throw FormatException('Invalid follow-up $followUpId');
    }
    return FollowUp(
      followUpId: followUpId,
      caseId: caseId,
      scheduledAt: scheduledAt,
      completedAt: completedAt,
      status: parsed,
      notes: notes,
    );
  }

  static DateTime _toDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.now();
  }
}
