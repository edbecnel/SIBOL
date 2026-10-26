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
    this.createdAt,
    this.createdByUid,
    this.createdByDisplayName,
    this.createdByStaffEmail,
  });

  final String followUpId;
  final String caseId;
  final DateTime scheduledAt;
  final DateTime? completedAt;
  final String status;
  final String notes;
  final DateTime? createdAt;
  final String? createdByUid;
  final String? createdByDisplayName;
  final String? createdByStaffEmail;

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
      createdAt: data['createdAt'] == null
          ? null
          : _toDate(data['createdAt']),
      createdByUid: data['createdByUid'] as String?,
      createdByDisplayName: data['createdByDisplayName'] as String?,
      createdByStaffEmail: data['createdByStaffEmail'] as String?,
    );
  }

  Map<String, dynamic> toFirestoreCreate({
    required String createdByUid,
    String? createdByDisplayName,
    String? createdByStaffEmail,
  }) {
    return {
      'caseId': caseId,
      'scheduledAt': Timestamp.fromDate(scheduledAt),
      if (completedAt != null) 'completedAt': Timestamp.fromDate(completedAt!),
      'status': status,
      'notes': notes,
      'createdByUid': createdByUid,
      if (createdByDisplayName != null && createdByDisplayName.trim().isNotEmpty)
        'createdByDisplayName': createdByDisplayName.trim(),
      if (createdByStaffEmail != null && createdByStaffEmail.trim().isNotEmpty)
        'createdByStaffEmail': createdByStaffEmail.trim(),
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  static FollowUpModel fromEntity(FollowUp entity) {
    return FollowUpModel(
      followUpId: entity.followUpId,
      caseId: entity.caseId,
      scheduledAt: entity.scheduledAt,
      completedAt: entity.completedAt,
      status: entity.status.firestoreValue,
      notes: entity.notes,
      createdAt: entity.createdAt,
      createdByUid: entity.createdByUid,
      createdByDisplayName: entity.createdByDisplayName,
      createdByStaffEmail: entity.createdByStaffEmail,
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
      createdAt: createdAt,
      createdByUid: createdByUid,
      createdByDisplayName: createdByDisplayName,
      createdByStaffEmail: createdByStaffEmail,
    );
  }

  static DateTime _toDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.now();
  }
}
