import 'package:sibol_app/features/coordination/domain/entities/coordination_staff_event.dart';
import 'package:sibol_app/features/coordination/domain/entities/coordination_thread.dart';
import 'package:sibol_app/features/coordination/domain/repositories/coordination_repository.dart';

class FakeCoordinationRepository implements CoordinationRepository {
  FakeCoordinationRepository({
    this.submittedReferralsStream,
    this.threadStreams = const {},
    this.staffEventStreams = const {},
  });

  final Stream<List<CoordinationThread>>? submittedReferralsStream;
  final Map<String, Stream<CoordinationThread?>> threadStreams;
  final Map<String, Stream<List<CoordinationStaffEvent>>> staffEventStreams;

  @override
  Stream<List<CoordinationThread>> watchSubmittedReferralsForOrg(String orgId) {
    return submittedReferralsStream ?? Stream.value(const []);
  }

  @override
  Stream<CoordinationThread?> watchThreadForBarangay(String threadId) {
    return threadStreams[threadId] ?? Stream.value(null);
  }

  @override
  Stream<List<CoordinationStaffEvent>> watchStaffEventsForThread(
    String threadId,
  ) {
    return staffEventStreams[threadId] ?? Stream.value(const []);
  }

  @override
  Future<CreateCoordinationReferralResult> createCoordinationReferral({
    required String assistanceRequestId,
    required String barangayReferralSummary,
  }) async =>
      throw UnimplementedError();

  @override
  Stream<List<CoordinationThread>> watchOpenThreadsForMoph(String hospitalOrgId) =>
      Stream.value(const []);

  @override
  Stream<CoordinationThread?> watchThreadForAssistanceRequest(
    String assistanceRequestId,
  ) =>
      Stream.value(null);

  @override
  Stream<CoordinationThread?> watchThreadForMoph(String threadId) =>
      watchThreadForBarangay(threadId);

  @override
  Stream<bool> watchReferralExistsForAssistanceRequest(String assistanceRequestId) =>
      Stream.value(false);
}
