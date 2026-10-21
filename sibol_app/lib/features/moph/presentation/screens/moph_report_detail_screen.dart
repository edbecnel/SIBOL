import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sibol_app/features/reporting/presentation/providers/report_providers.dart';
import 'package:sibol_app/features/reporting/presentation/widgets/aggregate_report_detail_body.dart';
import 'package:sibol_app/shared/widgets/app_error_widget.dart';
import 'package:sibol_app/shared/widgets/app_loading_indicator.dart';
import 'package:sibol_app/shared/widgets/fictional_data_banner.dart';

class MophReportDetailScreen extends ConsumerWidget {
  const MophReportDetailScreen({super.key, required this.reportId});

  final String reportId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportAsync = ref.watch(mophReportDetailProvider(reportId));

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
                return AggregateReportDetailBody(
                  report: report,
                  footerNote:
                      'Demonstration prototype: aggregate counts only. Individual barangay '
                      'case records are not shown to MOPH.',
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
