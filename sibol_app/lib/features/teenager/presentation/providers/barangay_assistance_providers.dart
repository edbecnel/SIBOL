import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sibol_app/core/providers/firebase_providers.dart';
import 'package:sibol_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:sibol_app/features/teenager/domain/entities/assistance_request.dart';

final barangayIncomingRequestsProvider =
    StreamProvider<List<AssistanceRequest>>((ref) {
  final profile = ref.watch(userProfileProvider).value;
  final barangay = profile?.assignedBarangay;
  if (barangay == null || barangay.isEmpty) {
    return Stream.error(
      StateError('Barangay site is not configured on your profile.'),
    );
  }
  return ref
      .watch(assistanceRequestRepositoryProvider)
      .watchIncomingForBarangay(barangay);
});

final barangayAssistanceRequestDetailProvider =
    StreamProvider.family<AssistanceRequest?, String>((ref, requestId) {
  final profile = ref.watch(userProfileProvider).value;
  final barangay = profile?.assignedBarangay;
  if (barangay == null || barangay.isEmpty) {
    return const Stream.empty();
  }
  return ref
      .watch(assistanceRequestRepositoryProvider)
      .watchRequestForBarangay(requestId, barangay);
});
