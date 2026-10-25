import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:sibol_app/core/constants/route_constants.dart';
import 'package:sibol_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:sibol_app/features/offline/domain/pending_operation.dart';
import 'package:sibol_app/features/offline/presentation/offline_providers.dart';
import 'package:sibol_app/features/reporting/domain/barangay_report_queue_payload.dart';
import 'package:sibol_app/features/reporting/presentation/providers/report_providers.dart';
import 'package:sibol_app/shared/widgets/app_error_widget.dart';
import 'package:sibol_app/shared/widgets/app_loading_indicator.dart';
import 'package:sibol_app/shared/widgets/fictional_data_banner.dart';

class BarangaySubmittedReportsScreen extends ConsumerWidget {
  const BarangaySubmittedReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportsAsync = ref.watch(barangaySubmittedReportsProvider);
    final uid = ref.watch(authStateChangesProvider).value?.uid;
    final pendingAsync =
        uid == null ? null : ref.watch(pendingOperationsProvider(uid));
    final dateFmt = DateFormat.yMMMd();

    return Scaffold(
      appBar: AppBar(title: const Text('Submitted reports')),
      body: Column(
        children: [
          const FictionalDataBanner(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Text(
              'Reports you have submitted to MOPH for your assigned barangay site.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          Expanded(
            child: reportsAsync.when(
              loading: () => const AppLoadingIndicator(
                message: 'Loading submitted reports…',
              ),
              error: (e, _) => AppErrorWidget(message: e.toString()),
              data: (reports) {
                final pendingReports = (pendingAsync?.asData?.value ??
                        const <PendingOperation>[])
                    .where(
                      (o) => o.kind == PendingOperationKind.barangayReportSubmit,
                    )
                    .toList();
                if (reports.isEmpty && pendingReports.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'No submitted reports yet. Use Submit report to MOPH on the '
                        'dashboard when you are ready to send an aggregate summary.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: pendingReports.length + reports.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    if (index < pendingReports.length) {
                      final op = pendingReports[index];
                      final counts =
                          BarangayReportQueuePayload.countsFrom(op.payload);
                      return Card(
                        color: Theme.of(context).colorScheme.surfaceContainerHighest,
                        child: ListTile(
                          leading: const Icon(Icons.cloud_off),
                          title: Text(counts.barangay),
                          subtitle: Text(
                            'Awaiting server confirmation · '
                            '${counts.totalCaseCount} case(s) in queued snapshot\n'
                            'Status: ${_pendingLabel(op.state)}',
                          ),
                          isThreeLine: true,
                        ),
                      );
                    }
                    final report = reports[index - pendingReports.length];
                    return Card(
                      child: ListTile(
                        title: Text(report.barangay),
                        subtitle: Text(
                          'Submitted ${dateFmt.format(report.submittedAt)}\n'
                          'Cases represented: ${report.totalCaseCount} · '
                          'Status: ${report.reportStatus}',
                        ),
                        isThreeLine: true,
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => context.push(
                          Routes.barangayReportReceipt(report.reportId),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  static String _pendingLabel(PendingOperationState state) {
    switch (state) {
      case PendingOperationState.savedLocally:
        return 'Saved locally';
      case PendingOperationState.waitingToSubmit:
        return 'Waiting to submit';
      case PendingOperationState.submitting:
        return 'Submitting…';
      case PendingOperationState.failedRetryable:
        return 'Waiting to retry';
      case PendingOperationState.failedPermanent:
        return 'Failed — needs attention';
      case PendingOperationState.conflict:
        return 'Conflict — needs attention';
      case PendingOperationState.submittedConfirmed:
        return 'Submitted';
    }
  }
}
