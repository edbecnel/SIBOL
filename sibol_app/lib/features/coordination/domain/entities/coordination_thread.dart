import 'package:equatable/equatable.dart';
import 'package:sibol_app/features/coordination/domain/coordination_phase.dart';
import 'package:sibol_app/features/coordination/domain/coordination_status.dart';
import 'package:sibol_app/features/teenager/domain/assistance_request_category.dart';

class CoordinationThread extends Equatable {
  const CoordinationThread({
    required this.threadId,
    this.orgId,
    required this.barangay,
    required this.displayRef,
    required this.category,
    required this.barangayReferralSummary,
    required this.phase,
    this.coordinationStatus,
    this.targetHospitalOrgId,
    required this.createdAt,
    required this.updatedAt,
    required this.lastStaffEventAt,
    required this.createdByUid,
  });

  final String threadId;
  final String? orgId;
  final String barangay;
  final String displayRef;
  final AssistanceRequestCategory category;
  final String barangayReferralSummary;
  final CoordinationPhase phase;
  final CoordinationStatus? coordinationStatus;
  final String? targetHospitalOrgId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime lastStaffEventAt;
  final String createdByUid;

  @override
  List<Object?> get props => [
        threadId,
        orgId,
        barangay,
        displayRef,
        category,
        barangayReferralSummary,
        phase,
        coordinationStatus,
        targetHospitalOrgId,
        createdAt,
        updatedAt,
        lastStaffEventAt,
        createdByUid,
      ];
}
