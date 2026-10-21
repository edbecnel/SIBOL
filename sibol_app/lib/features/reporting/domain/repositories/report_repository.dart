import 'package:sibol_app/features/reporting/domain/barangay_report_aggregate.dart';
import 'package:sibol_app/features/reporting/domain/entities/moph_aggregate_report.dart';

abstract class ReportRepository {
  Stream<List<MophAggregateReport>> watchSubmittedReportsForMoph();

  Stream<MophAggregateReport?> watchReportForMoph(String reportId);

  Stream<List<MophAggregateReport>> watchReportsForBarangay(String barangay);

  Future<String> submitBarangayAggregateReport({
    required String submittedByUid,
    required BarangayReportAggregateCounts counts,
  });
}
