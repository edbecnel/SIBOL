import 'package:cloud_functions/cloud_functions.dart';

class OpenBarangayCaseResult {
  const OpenBarangayCaseResult({
    required this.caseId,
    required this.assistanceRequestId,
    required this.idempotent,
  });

  final String caseId;
  final String assistanceRequestId;
  final bool idempotent;

  factory OpenBarangayCaseResult.fromMap(Map<String, dynamic> map) {
    return OpenBarangayCaseResult(
      caseId: map['caseId'] as String? ?? '',
      assistanceRequestId: map['assistanceRequestId'] as String? ?? '',
      idempotent: map['idempotent'] == true,
    );
  }
}

class CaseLifecycleApi {
  CaseLifecycleApi(this._functions);

  final FirebaseFunctions _functions;

  Future<OpenBarangayCaseResult> openCaseFromAssistance({
    required String assistanceRequestId,
    required String idempotencyKey,
  }) async {
    final callable =
        _functions.httpsCallable('regOpenBarangayCaseFromAssistance');
    final result = await callable.call<Map<String, dynamic>>({
      'assistanceRequestId': assistanceRequestId,
      'idempotencyKey': idempotencyKey,
    });
    return OpenBarangayCaseResult.fromMap(result.data);
  }

  Future<String> transitionCaseStatus({
    required String caseId,
    required String targetStatus,
    String? resolutionSummary,
    String? closureReason,
    String? closureNotes,
    String? reopenReason,
  }) async {
    final callable =
        _functions.httpsCallable('regTransitionBarangayCaseStatus');
    final result = await callable.call<Map<String, dynamic>>({
      'caseId': caseId,
      'targetStatus': targetStatus,
      if (resolutionSummary != null) 'resolutionSummary': resolutionSummary,
      if (closureReason != null) 'closureReason': closureReason,
      if (closureNotes != null) 'closureNotes': closureNotes,
      if (reopenReason != null) 'reopenReason': reopenReason,
    });
    return result.data['caseStatus'] as String? ?? targetStatus;
  }

  Future<String> updateMophCoordinationStatus({
    required String threadId,
    required String targetStatus,
    String? note,
  }) async {
    final callable =
        _functions.httpsCallable('regUpdateMophCoordinationStatus');
    final result = await callable.call<Map<String, dynamic>>({
      'threadId': threadId,
      'targetStatus': targetStatus,
      if (note != null) 'note': note,
    });
    return result.data['coordinationStatus'] as String? ?? targetStatus;
  }

  Future<String> respondToMophInformationRequest({
    required String threadId,
    required String responseSummary,
  }) async {
    final callable = _functions
        .httpsCallable('regBarangayRespondToMophInformationRequest');
    final result = await callable.call<Map<String, dynamic>>({
      'threadId': threadId,
      'responseSummary': responseSummary,
    });
    return result.data['coordinationStatus'] as String? ?? '';
  }
}
