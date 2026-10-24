import 'package:sibol_app/features/coordination/domain/entities/coordination_staff_event.dart';
import 'package:sibol_app/features/coordination/domain/entities/coordination_thread.dart';

class CreateCoordinationReferralResult {
  const CreateCoordinationReferralResult({
    required this.threadId,
    required this.displayRef,
  });

  final String threadId;
  final String displayRef;
}

abstract class CoordinationRepository {
  Future<CreateCoordinationReferralResult> createCoordinationReferral({
    required String assistanceRequestId,
    required String barangayReferralSummary,
  });

  Stream<List<CoordinationThread>> watchOpenThreadsForMoph();

  Stream<List<CoordinationThread>> watchSubmittedReferralsForOrg(String orgId);

  Stream<CoordinationThread?> watchThreadForMoph(String threadId);

  Stream<CoordinationThread?> watchThreadForBarangay(String threadId);

  Stream<List<CoordinationStaffEvent>> watchStaffEventsForThread(String threadId);

  Stream<bool> watchReferralExistsForAssistanceRequest(String assistanceRequestId);
}
