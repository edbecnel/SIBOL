import 'package:equatable/equatable.dart';

class CoordinationStaffEvent extends Equatable {
  const CoordinationStaffEvent({
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

  @override
  List<Object?> get props => [eventId, eventType, body, actorUid, createdAt];
}
