import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sibol_app/core/providers/firebase_providers.dart';
import 'package:sibol_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:sibol_app/features/org/presentation/providers/org_context_providers.dart';
import 'package:sibol_app/features/coordination/data/repositories/coordination_repository_impl.dart';
import 'package:sibol_app/features/coordination/domain/entities/coordination_staff_event.dart';
import 'package:sibol_app/features/coordination/domain/entities/coordination_thread.dart';
import 'package:sibol_app/features/coordination/domain/repositories/coordination_repository.dart';

final firebaseFunctionsProvider = Provider<FirebaseFunctions>((ref) {
  return FirebaseFunctions.instance;
});

final coordinationRepositoryProvider = Provider<CoordinationRepository>((ref) {
  return CoordinationRepositoryImpl(
    ref.watch(firestoreProvider),
    ref.watch(firebaseFunctionsProvider),
  );
});

Stream<List<CoordinationThread>> _mophCoordinationThreadsStream(Ref ref) {
  final profileAsync = ref.watch(userProfileProvider);
  final membershipsAsync = ref.watch(accountMembershipsProvider);
  if (profileAsync.isLoading || membershipsAsync.isLoading) {
    return const Stream<List<CoordinationThread>>.empty();
  }
  final orgId = ref.watch(mophHospitalOrgIdProvider);
  if (orgId == null) {
    return Stream.value(const []);
  }
  return ref.watch(coordinationRepositoryProvider).watchOpenThreadsForMoph(orgId);
}

final mophCoordinationThreadsProvider =
    StreamProvider<List<CoordinationThread>>((ref) {
  return _mophCoordinationThreadsStream(ref);
});

Stream<CoordinationThread?> _mophCoordinationThreadStream(Ref ref, String threadId) {
  final profileAsync = ref.watch(userProfileProvider);
  final membershipsAsync = ref.watch(accountMembershipsProvider);
  if (profileAsync.isLoading || membershipsAsync.isLoading) {
    return const Stream<CoordinationThread?>.empty();
  }
  if (ref.watch(mophHospitalOrgIdProvider) == null) {
    return Stream.value(null);
  }
  return ref.watch(coordinationRepositoryProvider).watchThreadForMoph(threadId);
}

final mophCoordinationThreadProvider =
    StreamProvider.family<CoordinationThread?, String>((ref, threadId) {
  return _mophCoordinationThreadStream(ref, threadId);
});

final mophCoordinationStaffEventsProvider =
    StreamProvider.family<List<CoordinationStaffEvent>, String>(
  (ref, threadId) {
    final profileAsync = ref.watch(userProfileProvider);
    final membershipsAsync = ref.watch(accountMembershipsProvider);
    if (profileAsync.isLoading || membershipsAsync.isLoading) {
      return const Stream<List<CoordinationStaffEvent>>.empty();
    }
    if (ref.watch(mophHospitalOrgIdProvider) == null) {
      return Stream.value(const []);
    }
    return ref
        .watch(coordinationRepositoryProvider)
        .watchStaffEventsForThread(threadId);
  },
);

final barangaySubmittedReferralsProvider =
    StreamProvider<List<CoordinationThread>>((ref) {
  final orgId = ref.watch(barangayCoordinationOrgIdProvider);
  if (orgId == null) {
    return Stream.error(
      StateError(
        'Organization context is not available for barangay coordination.',
      ),
    );
  }
  return ref
      .watch(coordinationRepositoryProvider)
      .watchSubmittedReferralsForOrg(orgId);
});

final barangayCoordinationThreadProvider =
    StreamProvider.family<CoordinationThread?, String>((ref, threadId) {
  return ref
      .watch(coordinationRepositoryProvider)
      .watchThreadForBarangay(threadId);
});

final barangayCoordinationStaffEventsProvider =
    StreamProvider.family<List<CoordinationStaffEvent>, String>(
  (ref, threadId) {
    return ref
        .watch(coordinationRepositoryProvider)
        .watchStaffEventsForThread(threadId);
  },
);

final assistanceReferralExistsProvider =
    StreamProvider.family<bool, String>((ref, assistanceRequestId) {
  return ref
      .watch(coordinationRepositoryProvider)
      .watchReferralExistsForAssistanceRequest(assistanceRequestId);
});
