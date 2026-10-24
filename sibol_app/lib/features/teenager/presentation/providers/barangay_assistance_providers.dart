import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sibol_app/core/providers/firebase_providers.dart';
import 'package:sibol_app/features/org/presentation/providers/org_context_providers.dart';
import 'package:sibol_app/features/teenager/domain/entities/assistance_request.dart';

final barangayIncomingRequestsProvider =
    StreamProvider<List<AssistanceRequest>>((ref) {
  final orgId = ref.watch(barangayAssistanceOrgIdProvider);
  if (orgId == null) {
    return Stream.error(
      StateError(
        'Organization context is not available for barangay assistance inbox.',
      ),
    );
  }
  return ref
      .watch(assistanceRequestRepositoryProvider)
      .watchIncomingForOrg(orgId);
});

final barangayAssistanceRequestDetailProvider =
    StreamProvider.family<AssistanceRequest?, String>((ref, requestId) {
  final orgId = ref.watch(barangayAssistanceOrgIdProvider);
  if (orgId == null) {
    return const Stream.empty();
  }
  return ref
      .watch(assistanceRequestRepositoryProvider)
      .watchRequestForOrg(requestId, orgId);
});
