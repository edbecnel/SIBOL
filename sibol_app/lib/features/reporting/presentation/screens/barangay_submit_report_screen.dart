import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:sibol_app/core/constants/route_constants.dart';
import 'package:sibol_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:sibol_app/features/reporting/domain/barangay_report_aggregate.dart';
import 'package:sibol_app/features/org/presentation/providers/org_context_providers.dart';
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
      final reportId = await ref
          .read(reportRepositoryProvider)
          .submitBarangayAggregateReport(
            submittedByUid: auth.uid,
            orgId: orgId,
            counts: counts,
          );
      if (!mounted) return;
      context.pushReplacement(Routes.barangayReportReceipt(reportId));
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
                        'Your profile does not have an assigned barangay site. '
                        'Contact the demonstration administrator before submitting.',
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
                    const SizedBox(height: 24),
                    _SummaryRow(label: 'Reporting barangay', value: counts.barangay),
                    _SummaryRow(
                      label: 'Total cases represented',
                      value: '${counts.totalCaseCount}',
                    ),
                    _SummaryRow(
                      label: 'Active',
                      value: '${counts.activeCaseCount}',
                    ),
                    _SummaryRow(
                      label: 'Follow-up scheduled',
                      value: '${counts.followUpScheduledCount}',
                    ),
                    _SummaryRow(
                      label: 'Follow-up completed',
                      value: '${counts.followUpCompletedCount}',
                    ),
                    _SummaryRow(
                      label: 'Closed',
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
