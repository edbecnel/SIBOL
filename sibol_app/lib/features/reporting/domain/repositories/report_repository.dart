import 'package:sibol_app/features/reporting/domain/barangay_report_aggregate.dart';
import 'package:sibol_app/features/reporting/domain/entities/moph_aggregate_report.dart';

abstract class ReportRepository {
  Stream<List<MophAggregateReport>> watchSubmittedReportsForMoph();

  Stream<MophAggregateReport?> watchReportForMoph(String reportId);

  Stream<List<MophAggregateReport>> watchReportsForOrg(String orgId);

  Stream<MophAggregateReport?> watchReportForOrg(
    String reportId,
    String orgId,
  );

  Future<String> submitBarangayAggregateReport({
    required String submittedByUid,
    required String orgId,
    required BarangayReportAggregateCounts counts,
  });

  /// Create-only write at [reportId] for offline replay idempotency.
  Future<void> createBarangayAggregateReport({
    required String reportId,
    required String submittedByUid,
    required String orgId,
    required BarangayReportAggregateCounts counts,
  });

  /// Returns whether an existing report document matches queued payload fields.
  Future<bool> barangayReportMatchesQueuedPayload({
    required String reportId,
    required String orgId,
    required String submittedByUid,
    required BarangayReportAggregateCounts counts,
  });
}
