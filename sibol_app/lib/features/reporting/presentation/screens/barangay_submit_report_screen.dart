import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:sibol_app/core/constants/route_constants.dart';
import 'package:sibol_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:sibol_app/features/cases/presentation/providers/case_providers.dart';
import 'package:sibol_app/features/offline/domain/pending_operation.dart';
import 'package:sibol_app/features/offline/presentation/offline_providers.dart';
import 'package:sibol_app/features/reporting/domain/barangay_report_aggregate.dart';
import 'package:sibol_app/features/reporting/domain/barangay_report_queue_payload.dart';
import 'package:sibol_app/features/org/presentation/providers/org_context_providers.dart';
import 'package:sibol_app/features/org/presentation/widgets/organization_directory_display.dart';
import 'package:sibol_app/features/reporting/presentation/providers/report_providers.dart';
import 'package:sibol_app/shared/widgets/app_error_widget.dart';
import 'package:sibol_app/shared/widgets/app_loading_indicator.dart';
import 'package:sibol_app/shared/widgets/fictional_data_banner.dart';

class BarangaySubmitReportScreen extends ConsumerStatefulWidget {
  const BarangaySubmitReportScreen({super.key});

  @override
  ConsumerState<BarangaySubmitReportScreen> createState() =>
      _BarangaySubmitReportScreenState();
}

class _BarangaySubmitReportScreenState
    extends ConsumerState<BarangaySubmitReportScreen> {
  bool _submitting = false;

  Future<void> _submit(BarangayReportAggregateCounts counts) async {
    final profile = ref.read(userProfileProvider).value;
    final auth = ref.read(authStateChangesProvider).value;
    if (profile == null || auth == null) return;
    final orgId = ref.read(barangayReportOrgIdProvider);
    if (orgId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Organization context is not available for report submit.'),
        ),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      final sync = ref.read(offlineSyncServiceProvider);
      final operationId =
          'rpt-${DateTime.now().microsecondsSinceEpoch}-${Random().nextInt(1 << 31)}';
      final pending = PendingOperation(
        operationId: operationId,
        ownerUid: auth.uid,
        kind: PendingOperationKind.barangayReportSubmit,
        state: PendingOperationState.waitingToSubmit,
        createdAt: DateTime.now(),
        payload: BarangayReportQueuePayload.encode(
          reportId: operationId,
          orgId: orgId,
          submittedByUid: auth.uid,
          counts: counts,
        ),
      );
      final online = await sync.hasConnectivity();
      if (!online) {
        await sync.enqueue(
          pending.copyWith(state: PendingOperationState.savedLocally),
        );
        ref.invalidate(pendingOperationsProvider(auth.uid));
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Report saved on this device only. MOPH will see it after sync.',
            ),
          ),
        );
        context.pushReplacement(Routes.barangaySubmittedReports);
        return;
      }
      await sync.enqueue(pending);
      await sync.syncForUser(auth.uid);
      ref.invalidate(pendingOperationsProvider(auth.uid));
      final stored =
          await ref.read(pendingOperationStoreProvider).loadForUser(auth.uid);
      final done = stored.firstWhere((o) => o.operationId == operationId);
      if (done.state == PendingOperationState.submittedConfirmed &&
          done.serverRequestId != null) {
        if (!mounted) return;
        context.pushReplacement(Routes.barangayReportReceipt(done.serverRequestId!));
        return;
      }
      if (done.state == PendingOperationState.failedPermanent ||
          done.state == PendingOperationState.conflict) {
        throw StateError(done.lastError ?? 'Report submission failed.');
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Report queued — waiting for server confirmation.'),
        ),
      );
      context.pushReplacement(Routes.barangaySubmittedReports);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Submit failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final aggregateAsync = ref.watch(barangayReportAggregateProvider);
    final casesMeta = ref.watch(casesStreamProvider).value;
    final dateFmt = DateFormat.yMMMd().add_jm();

    return Scaffold(
      appBar: AppBar(title: const Text('Submit report to MOPH')),
      body: Column(
        children: [
          const FictionalDataBanner(),
          Expanded(
            child: aggregateAsync.when(
              loading: () => const AppLoadingIndicator(
                message: 'Preparing report summary…',
              ),
              error: (e, _) => AppErrorWidget(message: e.toString()),
              data: (counts) {
                if (counts == null) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'Report summary is unavailable. Verify Barangay organization '
                        'membership and registry data before submitting.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }
                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Text(
                      'Aggregate summary only',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'This demonstration report includes counts only — no individual '
                      'case names or clinical findings.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    if (casesMeta != null &&
                        (casesMeta.isFromCache || casesMeta.hasPendingWrites)) ...[
                      const SizedBox(height: 12),
                      Text(
                        'Counts below are a local snapshot from cases on this device. '
                        'They may be incomplete or include unsynced case changes — not '
                        'authoritative server totals.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.error,
                            ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Text(
                      'Counts reflect each case’s caseStatus (one bucket per case). '
                      'Follow-up visit records are not counted separately.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 16),
                    Builder(
                      builder: (context) {
                        final orgId = ref.watch(barangayReportOrgIdProvider);
                        return OrganizationIdentityDetailRows(
                          orgId: orgId,
                          historicalSiteLabel: counts.barangay,
                        );
                      },
                    ),
                    _SummaryRow(
                      label: 'Total cases represented',
                      value: '${counts.totalCaseCount}',
                    ),
                    _SummaryRow(
                      label: 'Cases — status: Active',
                      value: '${counts.activeCaseCount}',
                    ),
                    _SummaryRow(
                      label: 'Cases — status: Follow-up scheduled',
                      value: '${counts.followUpScheduledCount}',
                    ),
                    _SummaryRow(
                      label: 'Cases — status: Follow-up completed',
                      value: '${counts.followUpCompletedCount}',
                    ),
                    _SummaryRow(
                      label: 'Cases — status: Closed',
                      value: '${counts.closedCaseCount}',
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Submission time will be recorded when you confirm (about ${dateFmt.format(DateTime.now())} local).',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: _submitting || counts.totalCaseCount == 0
                          ? null
                          : () => _confirmSubmit(context, counts),
                      icon: _submitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.send),
                      label: const Text('Submit report to MOPH'),
                    ),
                    if (counts.totalCaseCount == 0)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Text(
                          'Add at least one fictional case for your barangay site before submitting.',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
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

  Future<void> _confirmSubmit(
    BuildContext context,
    BarangayReportAggregateCounts counts,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Submit to MOPH?'),
        content: Text(
          'Submit aggregate counts for ${counts.totalCaseCount} fictional case(s) '
          'at ${counts.barangay}? MOPH will be able to review this summary.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Submit'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _submit(counts);
    }
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value});

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
            width: 160,
            child: Text(label, style: Theme.of(context).textTheme.labelLarge),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
