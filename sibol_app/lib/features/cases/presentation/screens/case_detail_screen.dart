import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:sibol_app/features/cases/domain/entities/case_record.dart';
import 'package:sibol_app/features/cases/presentation/providers/case_providers.dart';
import 'package:sibol_app/features/cases/presentation/widgets/case_follow_up_timeline.dart';
import 'package:sibol_app/shared/widgets/app_error_widget.dart';
import 'package:sibol_app/shared/widgets/app_loading_indicator.dart';
import 'package:sibol_app/shared/widgets/fictional_data_banner.dart';

class CaseDetailScreen extends ConsumerWidget {
  const CaseDetailScreen({super.key, required this.caseId});

  final String caseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final caseAsync = ref.watch(caseDetailStreamProvider(caseId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Case details'),
      ),
      body: Column(
        children: [
          const FictionalDataBanner(),
          Expanded(
            child: caseAsync.when(
              loading: () => const AppLoadingIndicator(message: 'Loading case…'),
              error: (e, _) => AppErrorWidget(
                message: 'Could not load this case. ${e.toString()}',
              ),
              data: (record) {
                if (record == null) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'This case was not found or you do not have access to view it.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }
                return CaseDetailBody(record: record, caseId: caseId);
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Read-only case fields for barangay review (T2-1).
class CaseDetailBody extends StatelessWidget {
  const CaseDetailBody({
    super.key,
    required this.record,
    required this.caseId,
  });

  final CaseRecord record;
  final String caseId;

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat.yMMMd();
    final dateTimeFmt = DateFormat.yMMMd().add_jm();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          record.demoName,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 16),
        _DetailTile(label: 'Case ID', value: record.caseId),
        _DetailTile(label: 'Age', value: '${record.age}'),
        _DetailTile(label: 'Barangay', value: _orDash(record.barangay)),
        _DetailTile(
          label: 'Case status',
          value: record.caseStatus.firestoreValue,
        ),
        _DetailTile(
          label: 'Report status',
          value: record.reportStatus.firestoreValue,
        ),
        _DetailTile(
          label: 'Registered',
          value: dateFmt.format(record.registeredAt),
        ),
        _DetailTile(
          label: 'Next follow-up',
          value: record.nextFollowUpAt == null
              ? '—'
              : dateTimeFmt.format(record.nextFollowUpAt!),
        ),
        _DetailTile(
          label: 'Notes',
          value: record.notes.trim().isEmpty ? '—' : record.notes.trim(),
        ),
        _DetailTile(
          label: 'Last updated',
          value: dateTimeFmt.format(record.updatedAt),
        ),
        const SizedBox(height: 24),
        Text(
          'Follow-ups (earliest scheduled first)',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        CaseFollowUpTimeline(caseId: caseId),
        const SizedBox(height: 24),
        Text(
          'Read-only view. Case editing is not available in this release.',
          style: Theme.of(context).textTheme.bodySmall,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  static String _orDash(String value) =>
      value.trim().isEmpty ? '—' : value.trim();
}

class _DetailTile extends StatelessWidget {
  const _DetailTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium,
          ),
          const SizedBox(height: 4),
          Text(value),
        ],
      ),
    );
  }
}
