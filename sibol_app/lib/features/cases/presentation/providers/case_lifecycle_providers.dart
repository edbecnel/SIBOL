import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sibol_app/features/cases/data/case_lifecycle_api.dart';
import 'package:sibol_app/features/coordination/domain/entities/coordination_thread.dart';
import 'package:sibol_app/features/coordination/presentation/providers/coordination_providers.dart';

final caseLifecycleApiProvider = Provider<CaseLifecycleApi>((ref) {
  return CaseLifecycleApi(ref.watch(firebaseFunctionsProvider));
});

final caseCoordinationForAssistanceProvider =
    StreamProvider.family<CoordinationThread?, String>((ref, assistanceRequestId) {
  return ref
      .watch(coordinationRepositoryProvider)
      .watchThreadForAssistanceRequest(assistanceRequestId);
});
