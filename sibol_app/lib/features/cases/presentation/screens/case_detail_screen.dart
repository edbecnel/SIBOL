import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sibol_app/core/constants/route_constants.dart';
import 'package:intl/intl.dart';
import 'package:sibol_app/features/cases/domain/entities/case_record.dart';
import 'package:sibol_app/features/cases/presentation/providers/case_providers.dart';
import 'package:sibol_app/core/providers/firebase_providers.dart';
import 'package:sibol_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:sibol_app/features/cases/domain/entities/follow_up.dart';
import 'package:sibol_app/features/cases/presentation/widgets/add_follow_up_dialog.dart';
import 'package:sibol_app/features/cases/presentation/widgets/case_firestore_sync_notice.dart';
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
        actions: [
          IconButton(
            icon: const Icon(Icons.event_note),
            tooltip: 'Add follow-up',
            onPressed: () => _showAddFollowUp(context, ref),
          ),
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: 'Edit case',
            onPressed: () =>
                context.push(Routes.barangayCaseEdit(caseId)),
          ),
        ],
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
              data: (snapshot) {
                final record = snapshot.data;
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
                return CaseDetailBody(
                  record: record,
                  caseId: caseId,
                  isFromCache: snapshot.isFromCache,
                  hasPendingWrites: snapshot.hasPendingWrites,
                  onAddFollowUp: () => _showAddFollowUp(context, ref),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showAddFollowUp(BuildContext context, WidgetRef ref) async {
    final uid = ref.read(authStateChangesProvider).value?.uid;
    if (uid == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sign in to record a follow-up.')),
        );
      }
      return;
    }
    final notes = await showDialog<String>(
      context: context,
      builder: (_) => const AddFollowUpDialog(),
    );
    if (notes == null || !context.mounted) return;
    final now = DateTime.now().toUtc();
    try {
      final repo = ref.read(caseRepositoryProvider);
      await repo.createFollowUp(
        followUp: FollowUp(
          followUpId: '',
          caseId: caseId,
          scheduledAt: now,
          completedAt: now,
          status: FollowUpStatus.completed,
          notes: notes,
        ),
        createdByUid: uid,
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Follow-up saved on this device. It will sync when online.',
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not save follow-up: $e')),
        );
      }
    }
  }
}

/// Read-only case fields for barangay review (T2-1).
class CaseDetailBody extends StatelessWidget {
  const CaseDetailBody({
    super.key,
    required this.record,
    required this.caseId,
    required this.isFromCache,
    required this.hasPendingWrites,
    required this.onAddFollowUp,
  });

  final CaseRecord record;
  final String caseId;
  final bool isFromCache;
  final bool hasPendingWrites;
  final VoidCallback onAddFollowUp;

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat.yMMMd();
    final dateTimeFmt = DateFormat.yMMMd().add_jm();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        CaseFirestoreSyncNotice(
          isFromCache: isFromCache,
          hasPendingWrites: hasPendingWrites,
        ),
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
        Row(
          children: [
            Expanded(
              child: Text(
                'Follow-ups (earliest first)',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            FilledButton.tonalIcon(
              onPressed: onAddFollowUp,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add follow-up'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        CaseFollowUpTimeline(caseId: caseId),
        const SizedBox(height: 24),
        Text(
          'Use the edit action above to update this fictional demonstration case.',
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
