import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sibol_app/core/providers/firebase_providers.dart';
import 'package:sibol_app/features/cases/domain/entities/case_record.dart';
import 'package:sibol_app/features/cases/domain/entities/follow_up.dart';
import 'package:sibol_app/features/org/presentation/providers/org_context_providers.dart';

final casesStreamProvider = StreamProvider<List<CaseRecord>>((ref) {
  final orgId = ref.watch(barangayCaseOrgIdProvider);
  if (orgId == null) {
    return Stream.error(
      StateError(
        'Organization context is not available. Check membership and primaryOrgId.',
      ),
    );
  }
  return ref.watch(caseRepositoryProvider).watchCasesForOrg(orgId);
});

final caseDetailStreamProvider =
    StreamProvider.family<CaseRecord?, String>((ref, caseId) {
  return ref.watch(caseRepositoryProvider).watchCase(caseId);
});

final followUpsStreamProvider =
    StreamProvider.family<List<FollowUp>, String>((ref, caseId) {
  return ref.watch(caseRepositoryProvider).watchFollowUps(caseId);
});
