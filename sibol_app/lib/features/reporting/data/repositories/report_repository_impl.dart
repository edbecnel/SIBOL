import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sibol_app/core/constants/firestore_paths.dart';
import 'package:sibol_app/features/reporting/data/models/moph_aggregate_report_model.dart';
import 'package:sibol_app/features/reporting/domain/barangay_report_aggregate.dart';
import 'package:sibol_app/features/reporting/domain/entities/moph_aggregate_report.dart';
import 'package:sibol_app/features/reporting/domain/repositories/report_repository.dart';

class ReportRepositoryImpl implements ReportRepository {
  ReportRepositoryImpl(this._firestore);

  final FirebaseFirestore _firestore;

  /// Matches rules requiring `acceptedAt != null` for MOPH/barangay list reads.
  static final Timestamp _minAcceptedAt = Timestamp.fromMillisecondsSinceEpoch(1);

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection(FirestorePaths.reports);

  @override
  Stream<List<MophAggregateReport>> watchSubmittedReportsForMoph() {
    return _collection
        .where('reportStatus', isEqualTo: 'submitted')
        .where('acceptedAt', isGreaterThan: _minAcceptedAt)
        .orderBy('acceptedAt', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map(
                (d) => MophAggregateReportModel.fromFirestore(d.id, d.data())
                    .toEntity(),
              )
              .toList(),
        );
  }

  @override
  Stream<MophAggregateReport?> watchReportForMoph(String reportId) {
    return _collection.doc(reportId).snapshots().map((snap) {
      if (!snap.exists) return null;
      final data = snap.data();
      if (data == null) return null;
      final model = MophAggregateReportModel.fromFirestore(snap.id, data);
      if (model.reportStatus != 'submitted') return null;
      return model.toEntity();
    });
  }

  @override
  Stream<List<MophAggregateReport>> watchReportsForOrg(String orgId) {
    return _collection
        .where('orgId', isEqualTo: orgId)
        .where('reportStatus', isEqualTo: 'submitted')
        .where('acceptedAt', isGreaterThan: _minAcceptedAt)
        .orderBy('acceptedAt', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map(
                (d) => MophAggregateReportModel.fromFirestore(d.id, d.data())
                    .toEntity(),
              )
              .toList(),
        );
  }

  @override
  Stream<MophAggregateReport?> watchReportForOrg(
    String reportId,
    String orgId,
  ) {
    return _collection.doc(reportId).snapshots().map((snap) {
      if (!snap.exists) return null;
      final data = snap.data();
      if (data == null) return null;
      final model = MophAggregateReportModel.fromFirestore(snap.id, data);
      if (model.orgId != orgId || model.reportStatus != 'submitted') {
        return null;
      }
      return model.toEntity();
    });
  }

  @override
  Future<String> submitBarangayAggregateReport({
    required String submittedByUid,
    required String orgId,
    required BarangayReportAggregateCounts counts,
  }) async {
    final now = DateTime.now();
    final model = MophAggregateReportModel(
      reportId: '',
      barangay: counts.barangay,
      orgId: orgId,
      submittedAt: now,
      submittedByUid: submittedByUid,
      totalCaseCount: counts.totalCaseCount,
      activeCaseCount: counts.activeCaseCount,
      followUpScheduledCount: counts.followUpScheduledCount,
      followUpCompletedCount: counts.followUpCompletedCount,
      closedCaseCount: counts.closedCaseCount,
      reportStatus: 'submitted',
      acceptedAt: now,
    );
    final doc = await _collection.add(model.toFirestoreCreate());
    return doc.id;
  }

  @override
  Future<void> createBarangayAggregateReport({
    required String reportId,
    required String submittedByUid,
    required String orgId,
    required BarangayReportAggregateCounts counts,
  }) async {
    final now = DateTime.now();
    final model = MophAggregateReportModel(
      reportId: reportId,
      barangay: counts.barangay,
      orgId: orgId,
      submittedAt: now,
      submittedByUid: submittedByUid,
      totalCaseCount: counts.totalCaseCount,
      activeCaseCount: counts.activeCaseCount,
      followUpScheduledCount: counts.followUpScheduledCount,
      followUpCompletedCount: counts.followUpCompletedCount,
      closedCaseCount: counts.closedCaseCount,
      reportStatus: 'submitted',
      acceptedAt: now,
    );
    final ref = _collection.doc(reportId);
    try {
      // Create-only: no pre-read (read rules require an existing submitted doc).
      await ref.set(model.toFirestoreCreate());
      return;
    } on FirebaseException catch (e) {
      if (e.code != 'permission-denied') {
        rethrow;
      }
      // Update is denied; distinguish idempotent duplicate from failed create.
      if (await barangayReportMatchesQueuedPayload(
        reportId: reportId,
        orgId: orgId,
        submittedByUid: submittedByUid,
        counts: counts,
      )) {
        return;
      }
      try {
        final snap = await ref.get();
        if (snap.exists) {
          throw FirebaseException(
            plugin: 'cloud_firestore',
            code: 'already-exists',
            message: 'Report document already exists.',
          );
        }
      } on FirebaseException catch (readError) {
        if (readError.code == 'already-exists') {
          rethrow;
        }
        // Nonexistent or unreadable — propagate the original create denial.
      }
      rethrow;
    }
  }

  @override
  Future<bool> barangayReportMatchesQueuedPayload({
    required String reportId,
    required String orgId,
    required String submittedByUid,
    required BarangayReportAggregateCounts counts,
  }) async {
    final snap = await _collection.doc(reportId).get();
    if (!snap.exists || snap.data() == null) return false;
    final data = snap.data()!;
    return data['orgId'] == orgId &&
        data['submittedByUid'] == submittedByUid &&
        data['barangay'] == counts.barangay &&
        data['totalCaseCount'] == counts.totalCaseCount &&
        data['activeCaseCount'] == counts.activeCaseCount &&
        data['followUpScheduledCount'] == counts.followUpScheduledCount &&
        data['followUpCompletedCount'] == counts.followUpCompletedCount &&
        data['closedCaseCount'] == counts.closedCaseCount &&
        data['reportStatus'] == 'submitted';
  }
}
