import 'package:equatable/equatable.dart';
import 'package:sibol_app/features/coordination/domain/coordination_phase.dart';
import 'package:sibol_app/features/teenager/domain/assistance_request_category.dart';

class CoordinationThread extends Equatable {
  const CoordinationThread({
    required this.threadId,
    required this.barangay,
    required this.displayRef,
    required this.category,
    required this.barangayReferralSummary,
    required this.phase,
    required this.createdAt,
    required this.updatedAt,
    required this.lastStaffEventAt,
    required this.createdByUid,
  });

  final String threadId;
  final String barangay;
  final String displayRef;
  final AssistanceRequestCategory category;
  final String barangayReferralSummary;
  final CoordinationPhase phase;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime lastStaffEventAt;
  final String createdByUid;

  @override
  List<Object?> get props => [
        threadId,
        barangay,
        displayRef,
        category,
        barangayReferralSummary,
        phase,
        createdAt,
        updatedAt,
        lastStaffEventAt,
        createdByUid,
      ];
}
