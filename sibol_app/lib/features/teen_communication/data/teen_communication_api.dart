import 'package:cloud_functions/cloud_functions.dart';

class TeenCommunicationApi {
  TeenCommunicationApi(this._functions);

  final FirebaseFunctions _functions;

  Future<void> publishProgressUpdate({
    required String assistanceRequestId,
    required String templateCode,
    required String idempotencyKey,
    String communicationKind = 'progress',
  }) async {
    await _functions.httpsCallable('regPublishTeenAssistanceCommunication').call({
      'assistanceRequestId': assistanceRequestId,
      'templateCode': templateCode,
      'idempotencyKey': idempotencyKey,
      'communicationKind': communicationKind,
    });
  }

  Future<void> confirmCoordinationOutcome({
    required String assistanceRequestId,
    required String idempotencyKey,
    bool includeFollowUp = false,
  }) async {
    await _functions.httpsCallable('regConfirmTeenCoordinationOutcome').call({
      'assistanceRequestId': assistanceRequestId,
      'idempotencyKey': idempotencyKey,
      if (includeFollowUp)
        'followUpTemplateCode': 'follow_up_contact_barangay',
    });
  }
}
