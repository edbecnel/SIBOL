import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:sibol_app/features/org/presentation/widgets/organization_directory_display.dart';
import 'package:sibol_app/features/reporting/domain/entities/moph_aggregate_report.dart';

class AggregateReportDetailBody extends ConsumerWidget {
  const AggregateReportDetailBody({
    super.key,
    required this.report,
    required this.footerNote,
  });

  final MophAggregateReport report;
  final String footerNote;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dateFmt = DateFormat.yMMMd().add_jm();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        AggregateReportDetailRow(label: 'Reference', value: report.reportId),
        OrganizationIdentityDetailRows(
          orgId: report.orgId.isNotEmpty ? report.orgId : null,
        ),
        AggregateReportDetailRow(
          label: 'Submitted',
          value: dateFmt.format(report.submittedAt),
        ),
        AggregateReportDetailRow(label: 'Status', value: report.reportStatus),
        const SizedBox(height: 16),
        Text(
          'Case counts by lifecycle status (aggregate)',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 4),
        Text(
          'Each case appears in exactly one bucket according to its caseStatus field. '
          'Individual follow-up visits are not counted here.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 8),
        AggregateReportDetailRow(
          label: 'Total cases',
          value: '${report.totalCaseCount}',
        ),
        AggregateReportDetailRow(
          label: 'Cases — status: Active',
          value: '${report.activeCaseCount}',
        ),
        AggregateReportDetailRow(
          label: 'Cases — status: Follow-up scheduled',
          value: '${report.followUpScheduledCount}',
        ),
        AggregateReportDetailRow(
          label: 'Cases — status: Follow-up completed',
          value: '${report.followUpCompletedCount}',
        ),
        AggregateReportDetailRow(
          label: 'Cases — status: Closed',
          value: '${report.closedCaseCount}',
        ),
        const SizedBox(height: 24),
        Text(footerNote, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class AggregateReportDetailRow extends StatelessWidget {
  const AggregateReportDetailRow({
    super.key,
    required this.label,
    required this.value,
  });

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
