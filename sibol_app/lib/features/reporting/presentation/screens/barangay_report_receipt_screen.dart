import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sibol_app/features/reporting/presentation/providers/report_providers.dart';
import 'package:sibol_app/features/reporting/presentation/widgets/aggregate_report_detail_body.dart';
import 'package:sibol_app/shared/widgets/app_error_widget.dart';
import 'package:sibol_app/shared/widgets/app_loading_indicator.dart';
import 'package:sibol_app/shared/widgets/fictional_data_banner.dart';

class BarangayReportReceiptScreen extends ConsumerWidget {
  const BarangayReportReceiptScreen({super.key, required this.reportId});

  final String reportId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportAsync = ref.watch(barangayReportReceiptProvider(reportId));

    return Scaffold(
      appBar: AppBar(title: const Text('Submission receipt')),
      body: Column(
        children: [
          const FictionalDataBanner(),
          Expanded(
            child: reportAsync.when(
              loading: () => const AppLoadingIndicator(
                message: 'Loading submission receipt…',
              ),
              error: (e, _) => AppErrorWidget(message: e.toString()),
              data: (report) {
                if (report == null) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'Receipt not found or not available for your barangay site.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }
                return AggregateReportDetailBody(
                  report: report,
                  footerNote:
                      'This receipt confirms your aggregate report was submitted to MOPH '
                      'for demonstration purposes. It does not include individual case names '
                      'or clinical details. You can return to this receipt from Submitted '
                      'reports after signing in again.',
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
