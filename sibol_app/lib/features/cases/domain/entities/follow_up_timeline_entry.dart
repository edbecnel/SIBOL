import 'package:equatable/equatable.dart';
import 'package:sibol_app/features/cases/domain/entities/follow_up.dart';

/// Follow-up row with Firestore client metadata for offline UX.
class FollowUpTimelineEntry extends Equatable {
  const FollowUpTimelineEntry({
    required this.followUp,
    required this.isFromCache,
    this.hasPendingWrites = false,
  });

  final FollowUp followUp;
  final bool isFromCache;
  final bool hasPendingWrites;

  @override
  List<Object?> get props => [followUp, isFromCache, hasPendingWrites];
}
