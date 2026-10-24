import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sibol_app/features/coordination/domain/entities/coordination_staff_event.dart';

class CoordinationStaffEventModel {
  CoordinationStaffEventModel({
    required this.eventId,
    required this.eventType,
    required this.body,
    required this.actorUid,
    required this.createdAt,
  });

  final String eventId;
  final String eventType;
  final String body;
  final String actorUid;
  final DateTime createdAt;

  factory CoordinationStaffEventModel.fromFirestore(
    String eventId,
    Map<String, dynamic> data,
  ) {
    return CoordinationStaffEventModel(
      eventId: eventId,
      eventType: data['eventType'] as String,
      body: data['body'] as String,
      actorUid: data['actorUid'] as String,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  CoordinationStaffEvent toEntity() {
    return CoordinationStaffEvent(
      eventId: eventId,
      eventType: eventType,
      body: body,
      actorUid: actorUid,
      createdAt: createdAt,
    );
  }
}
