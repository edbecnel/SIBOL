import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sibol_app/core/providers/firebase_providers.dart';
import 'package:sibol_app/features/auth/presentation/providers/auth_providers.dart';
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

final mophCoordinationThreadsProvider =
    StreamProvider<List<CoordinationThread>>((ref) {
  return ref.watch(coordinationRepositoryProvider).watchOpenThreadsForMoph();
});

final mophCoordinationThreadProvider =
    StreamProvider.family<CoordinationThread?, String>((ref, threadId) {
  return ref
      .watch(coordinationRepositoryProvider)
      .watchThreadForMoph(threadId);
});

final mophCoordinationStaffEventsProvider =
    StreamProvider.family<List<CoordinationStaffEvent>, String>(
  (ref, threadId) {
    return ref
        .watch(coordinationRepositoryProvider)
        .watchStaffEventsForThread(threadId);
  },
);

final barangaySubmittedReferralsProvider =
    StreamProvider<List<CoordinationThread>>((ref) {
  final profile = ref.watch(userProfileProvider).value;
  final barangay = profile?.assignedBarangay;
  if (barangay == null || barangay.isEmpty) {
    return Stream.error(
      StateError('Barangay site is not configured on your profile.'),
    );
  }
  return ref
      .watch(coordinationRepositoryProvider)
      .watchSubmittedReferralsForBarangay(barangay);
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
