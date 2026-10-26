import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sibol_app/core/domain/firestore_document_snapshot.dart';
import 'package:sibol_app/core/domain/firestore_list_snapshot.dart';
import 'package:sibol_app/core/providers/firebase_providers.dart';
import 'package:sibol_app/features/cases/domain/entities/case_list_entry.dart';
import 'package:sibol_app/features/cases/domain/entities/case_record.dart';
import 'package:sibol_app/features/cases/domain/entities/follow_up_timeline_entry.dart';
import 'package:sibol_app/features/cases/data/case_registration_api.dart';
import 'package:sibol_app/features/org/presentation/providers/org_context_providers.dart';

final caseRegistrationApiProvider = Provider<CaseRegistrationApi>((ref) {
  return CaseRegistrationApi(ref.watch(firebaseFunctionsProvider));
});

final casesStreamProvider =
    StreamProvider<FirestoreListSnapshot<CaseListEntry>>((ref) {
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
    StreamProvider.family<FirestoreDocumentSnapshot<CaseRecord>, String>(
        (ref, caseId) {
  return ref.watch(caseRepositoryProvider).watchCase(caseId);
});

/// Cache-first case record for the edit form (offline-safe bootstrap).
final caseEditRecordProvider = StreamProvider.family<CaseRecord, String>(
  (ref, caseId) {
    return ref.watch(caseRepositoryProvider).watchCaseForEdit(caseId);
  },
);

final followUpsStreamProvider =
    StreamProvider.family<List<FollowUpTimelineEntry>, String>((ref, caseId) {
  return ref.watch(caseRepositoryProvider).watchFollowUps(caseId);
});
