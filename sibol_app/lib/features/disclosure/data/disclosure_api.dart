import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sibol_app/core/providers/firebase_providers.dart';

class DisclosureApi {
  DisclosureApi(this._functions);

  final FirebaseFunctions _functions;

  Future<String> requestAuthorization({
    required String assistanceRequestId,
    required String purposeCode,
    required List<String> requestedCategories,
  }) async {
    final callable = _functions.httpsCallable('regRequestMophDisclosureAuthorization');
    final result = await callable.call<Map<String, dynamic>>({
      'assistanceRequestId': assistanceRequestId,
      'purposeCode': purposeCode,
      'requestedCategories': requestedCategories,
    });
    return result.data['authorizationId'] as String;
  }

  Future<String> recordDecision({
    required String authorizationId,
    required String decision,
  }) async {
    final callable = _functions.httpsCallable('regRecordTeenDisclosureDecision');
    final result = await callable.call<Map<String, dynamic>>({
      'authorizationId': authorizationId,
      'decision': decision,
    });
    return result.data['status'] as String;
  }

  Future<void> withdraw({required String authorizationId}) async {
    final callable = _functions.httpsCallable('regWithdrawDisclosureAuthorization');
    await callable.call<Map<String, dynamic>>({
      'authorizationId': authorizationId,
    });
  }
}

final disclosureApiProvider = Provider<DisclosureApi>((ref) {
  return DisclosureApi(ref.watch(firebaseFunctionsProvider));
});
