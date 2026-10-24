import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sibol_app/features/coordination/domain/coordination_phase.dart';
import 'package:sibol_app/features/coordination/domain/entities/coordination_thread.dart';
import 'package:sibol_app/features/teenager/domain/assistance_request_category.dart';

class CoordinationThreadModel {
  CoordinationThreadModel({
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
  final String category;
  final String barangayReferralSummary;
  final String phase;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime lastStaffEventAt;
  final String createdByUid;

  factory CoordinationThreadModel.fromFirestore(
    String threadId,
    Map<String, dynamic> data,
  ) {
    return CoordinationThreadModel(
      threadId: threadId,
      barangay: data['barangay'] as String,
      displayRef: data['displayRef'] as String,
      category: data['category'] as String,
      barangayReferralSummary: data['barangayReferralSummary'] as String,
      phase: data['phase'] as String,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      lastStaffEventAt: (data['lastStaffEventAt'] as Timestamp).toDate(),
      createdByUid: data['createdByUid'] as String,
    );
  }

  CoordinationThread toEntity() {
    final cat = AssistanceRequestCategory.fromFirestore(category);
    final ph = CoordinationPhase.fromFirestore(phase);
    if (cat == null || ph == null) {
      throw FormatException('Invalid coordination thread document.');
    }
    return CoordinationThread(
      threadId: threadId,
      barangay: barangay,
      displayRef: displayRef,
      category: cat,
      barangayReferralSummary: barangayReferralSummary,
      phase: ph,
      createdAt: createdAt,
      updatedAt: updatedAt,
      lastStaffEventAt: lastStaffEventAt,
      createdByUid: createdByUid,
    );
  }
}
