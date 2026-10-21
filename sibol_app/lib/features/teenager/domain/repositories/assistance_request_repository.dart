import 'package:sibol_app/features/teenager/domain/assistance_request_category.dart';
import 'package:sibol_app/features/teenager/domain/entities/assistance_request.dart';

abstract class AssistanceRequestRepository {
  Stream<List<AssistanceRequest>> watchMyRequests(String teenUid);

  Stream<AssistanceRequest?> watchRequest(String requestId, String teenUid);

  Stream<List<AssistanceRequest>> watchIncomingForBarangay(String barangay);

  Stream<AssistanceRequest?> watchRequestForBarangay(
    String requestId,
    String barangay,
  );

  Future<String> createRequest({
    required String teenUid,
    required String barangay,
    required AssistanceRequestCategory category,
    required String description,
  });

  Future<void> acknowledgeRequest({
    required String requestId,
    required String barangay,
    required String barangayStaffUid,
  });
}
