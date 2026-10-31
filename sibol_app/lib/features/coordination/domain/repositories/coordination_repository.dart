import 'package:sibol_app/features/coordination/domain/entities/coordination_staff_event.dart';
import 'package:sibol_app/features/coordination/domain/entities/coordination_thread.dart';

class CreateCoordinationReferralResult {
  const CreateCoordinationReferralResult({
    required this.threadId,
    required this.displayRef,
    this.disclosureMode,
  });

  final String threadId;
  final String displayRef;
  final String? disclosureMode;
}

class StructuredCoordinationReferralInput {
  const StructuredCoordinationReferralInput({
    required this.assistanceRequestId,
    required this.disclosureMode,
    required this.referralPurposeCode,
    required this.coordinationNeedCodes,
    this.authorizationId,
  });

  final String assistanceRequestId;
  final String disclosureMode;
  final String referralPurposeCode;
  final List<String> coordinationNeedCodes;
  final String? authorizationId;
}

abstract class CoordinationRepository {
  Future<CreateCoordinationReferralResult> createCoordinationReferral(
    StructuredCoordinationReferralInput input,
  );

  Stream<List<CoordinationThread>> watchOpenThreadsForMoph(String hospitalOrgId);

  Stream<List<CoordinationThread>> watchSubmittedReferralsForOrg(String orgId);

  Stream<CoordinationThread?> watchThreadForMoph(String threadId);

  Stream<CoordinationThread?> watchThreadForBarangay(String threadId);

  Stream<List<CoordinationStaffEvent>> watchStaffEventsForThread(String threadId);

  Stream<bool> watchReferralExistsForAssistanceRequest(String assistanceRequestId);

  Stream<CoordinationThread?> watchThreadForAssistanceRequest(
    String assistanceRequestId,
  );
}
