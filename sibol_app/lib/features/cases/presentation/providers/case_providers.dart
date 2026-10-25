import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sibol_app/core/domain/firestore_document_snapshot.dart';
import 'package:sibol_app/core/domain/firestore_list_snapshot.dart';
import 'package:sibol_app/core/providers/firebase_providers.dart';
import 'package:sibol_app/features/cases/domain/entities/case_record.dart';
import 'package:sibol_app/features/cases/domain/entities/follow_up_timeline_entry.dart';
import 'package:sibol_app/features/org/presentation/providers/org_context_providers.dart';

final casesStreamProvider =
    StreamProvider<FirestoreListSnapshot<CaseRecord>>((ref) {
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

final followUpsStreamProvider =
    StreamProvider.family<List<FollowUpTimelineEntry>, String>((ref, caseId) {
  return ref.watch(caseRepositoryProvider).watchFollowUps(caseId);
});
