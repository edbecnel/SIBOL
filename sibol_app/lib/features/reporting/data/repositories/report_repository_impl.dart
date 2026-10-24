import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sibol_app/core/constants/demo_org_constants.dart';
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
  Stream<List<MophAggregateReport>> watchReportsForBarangay(String barangay) {
    return _collection
        .where('barangay', isEqualTo: barangay)
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
  Stream<MophAggregateReport?> watchReportForBarangay(
    String reportId,
    String barangay,
  ) {
    return _collection.doc(reportId).snapshots().map((snap) {
      if (!snap.exists) return null;
      final data = snap.data();
      if (data == null) return null;
      final model = MophAggregateReportModel.fromFirestore(snap.id, data);
      if (model.barangay != barangay || model.reportStatus != 'submitted') {
        return null;
      }
      return model.toEntity();
    });
  }

  @override
  Future<String> submitBarangayAggregateReport({
    required String submittedByUid,
    required BarangayReportAggregateCounts counts,
  }) async {
    final now = DateTime.now();
    final model = MophAggregateReportModel(
      reportId: '',
      barangay: counts.barangay,
      orgId: DemoOrgConstants.barangayTresOrgId,
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
}
