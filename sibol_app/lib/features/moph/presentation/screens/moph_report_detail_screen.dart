import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:sibol_app/features/reporting/presentation/providers/report_providers.dart';
import 'package:sibol_app/shared/widgets/app_error_widget.dart';
import 'package:sibol_app/shared/widgets/app_loading_indicator.dart';
import 'package:sibol_app/shared/widgets/fictional_data_banner.dart';

class MophReportDetailScreen extends ConsumerWidget {
  const MophReportDetailScreen({super.key, required this.reportId});

  final String reportId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportAsync = ref.watch(mophReportDetailProvider(reportId));
    final dateFmt = DateFormat.yMMMd().add_jm();

    return Scaffold(
      appBar: AppBar(title: const Text('Submitted report')),
      body: Column(
        children: [
          const FictionalDataBanner(),
          Expanded(
            child: reportAsync.when(
              loading: () => const AppLoadingIndicator(
                message: 'Loading report…',
              ),
              error: (e, _) => AppErrorWidget(message: e.toString()),
              data: (report) {
                if (report == null) {
                  return const Center(
                    child: Text('Report not found or not available.'),
                  );
                }
                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _DetailRow(label: 'Reference', value: report.reportId),
                    _DetailRow(label: 'Reporting barangay', value: report.barangay),
                    _DetailRow(
                      label: 'Submitted',
                      value: dateFmt.format(report.submittedAt),
                    ),
                    _DetailRow(label: 'Status', value: report.reportStatus),
                    const SizedBox(height: 16),
                    Text(
                      'Case counts (aggregate)',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 8),
                    _DetailRow(
                      label: 'Total cases',
                      value: '${report.totalCaseCount}',
                    ),
                    _DetailRow(
                      label: 'Active',
                      value: '${report.activeCaseCount}',
                    ),
                    _DetailRow(
                      label: 'Follow-up scheduled',
                      value: '${report.followUpScheduledCount}',
                    ),
                    _DetailRow(
                      label: 'Follow-up completed',
                      value: '${report.followUpCompletedCount}',
                    ),
                    _DetailRow(
                      label: 'Closed',
                      value: '${report.closedCaseCount}',
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Demonstration prototype: aggregate counts only. Individual barangay '
                      'case records are not shown to MOPH.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(label, style: Theme.of(context).textTheme.labelLarge),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
