import 'package:sibol_app/core/domain/firestore_list_snapshot.dart';
import 'package:sibol_app/features/teenager/domain/entities/assistance_request.dart';

abstract class AssistanceRequestRepository {
  Stream<FirestoreListSnapshot<AssistanceRequest>> watchMyRequests(String teenUid);

  Stream<AssistanceRequest?> watchRequest(String requestId, String teenUid);

  Stream<FirestoreListSnapshot<AssistanceRequest>> watchIncomingForOrg(
    String orgId,
  );

  Stream<AssistanceRequest?> watchRequestForOrg(
    String requestId,
    String orgId,
  );


  Future<void> acknowledgeRequest({
    required String requestId,
    required String orgId,
    required String idempotencyKey,
  });
}
