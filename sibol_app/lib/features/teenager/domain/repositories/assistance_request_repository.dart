import 'package:sibol_app/features/teenager/domain/assistance_request_category.dart';
import 'package:sibol_app/features/teenager/domain/entities/assistance_request.dart';

abstract class AssistanceRequestRepository {
  Stream<List<AssistanceRequest>> watchMyRequests(String teenUid);

  Stream<AssistanceRequest?> watchRequest(String requestId, String teenUid);

  Stream<List<AssistanceRequest>> watchIncomingForOrg(String orgId);

  Stream<AssistanceRequest?> watchRequestForOrg(
    String requestId,
    String orgId,
  );


  Future<void> acknowledgeRequest({
    required String requestId,
    required String barangay,
    required String barangayStaffUid,
  });
}
