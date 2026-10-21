import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sibol_app/core/providers/firebase_providers.dart';
import 'package:sibol_app/features/cases/domain/entities/case_record.dart';
import 'package:sibol_app/features/cases/domain/entities/follow_up.dart';

final casesStreamProvider = StreamProvider<List<CaseRecord>>((ref) {
  return ref.watch(caseRepositoryProvider).watchCases();
});

final caseDetailStreamProvider =
    StreamProvider.family<CaseRecord?, String>((ref, caseId) {
  return ref.watch(caseRepositoryProvider).watchCase(caseId);
});

final followUpsStreamProvider =
    StreamProvider.family<List<FollowUp>, String>((ref, caseId) {
  return ref.watch(caseRepositoryProvider).watchFollowUps(caseId);
});
