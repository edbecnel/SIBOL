import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sibol_app/core/constants/route_constants.dart';
import 'package:sibol_app/features/cases/domain/case_status.dart';
import 'package:sibol_app/features/cases/domain/entities/case_record.dart';
import 'package:sibol_app/features/cases/presentation/providers/case_lifecycle_providers.dart';
import 'package:sibol_app/features/coordination/domain/coordination_status.dart';
import 'package:sibol_app/shared/widgets/app_button.dart';

class CaseLifecyclePanel extends ConsumerStatefulWidget {
  const CaseLifecyclePanel({
    super.key,
    required this.record,
  });

  final CaseRecord record;

  @override
  ConsumerState<CaseLifecyclePanel> createState() => _CaseLifecyclePanelState();
}

class _CaseLifecyclePanelState extends ConsumerState<CaseLifecyclePanel> {
  bool _busy = false;

  Future<bool> _isOnline() async {
    final result = await Connectivity().checkConnectivity();
    return !result.contains(ConnectivityResult.none);
  }

  Future<void> _runLifecycleAction(Future<void> Function() action) async {
    if (_busy) return;
    if (!await _isOnline()) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Case lifecycle actions require an online connection.',
            ),
          ),
        );
      }
      return;
    }
    setState(() => _busy = true);
    try {
      await action();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<String?> _promptText(
    BuildContext context, {
    required String title,
    required String label,
    int minLength = 10,
  }) async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(labelText: label),
          maxLines: 4,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              final text = controller.text.trim();
              if (text.length < minLength) return;
              Navigator.pop(ctx, text);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final record = widget.record;
    if (!record.isAssistanceLinkedCase) {
      return const SizedBox.shrink();
    }

    final assistanceId = record.assistanceRequestId!;
    final coordinationAsync =
        ref.watch(caseCoordinationForAssistanceProvider(assistanceId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Case lifecycle', style: Theme.of(context).textTheme.titleMedium),
        if (record.assignedCoordinatorUid != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text('Coordinator: ${record.assignedCoordinatorUid}'),
          ),
        const SizedBox(height: 12),
        coordinationAsync.when(
          loading: () => const Text('Loading hospital coordination…'),
          error: (e, _) => Text('Coordination: unavailable ($e)'),
          data: (thread) {
            if (thread == null) {
              return const Text('No hospital referral submitted yet.');
            }
            final status = thread.coordinationStatus;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Referral ${thread.displayRef}'),
                Text(
                  status?.label ??
                      CoordinationStatus.submitted.label,
                ),
                TextButton(
                  onPressed: () => context.push(
                    Routes.barangaySubmittedReferralDetail(thread.threadId),
                  ),
                  child: const Text('View referral details'),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            if (record.caseStatus == CaseStatus.open)
              AppButton.primary(
                label: 'Start case work',
                onPressed: _busy
                    ? null
                    : () => _runLifecycleAction(() async {
                          await ref.read(caseLifecycleApiProvider).transitionCaseStatus(
                                caseId: record.caseId,
                                targetStatus: CaseStatus.inProgress.firestoreValue,
                              );
                        }),
              ),
            if (record.caseStatus == CaseStatus.inProgress)
              AppButton.primary(
                label: 'Mark resolved',
                onPressed: _busy
                    ? null
                    : () async {
                        final summary = await _promptText(
                          context,
                          title: 'Resolution outcome',
                          label: 'Describe how the case was resolved',
                        );
                        if (summary == null) return;
                        await _runLifecycleAction(() async {
                          await ref.read(caseLifecycleApiProvider).transitionCaseStatus(
                                caseId: record.caseId,
                                targetStatus: CaseStatus.resolved.firestoreValue,
                                resolutionSummary: summary,
                              );
                        });
                      },
              ),
            if (record.caseStatus == CaseStatus.resolved)
              AppButton.primary(
                label: 'Close case',
                onPressed: _busy
                    ? null
                    : () async {
                        final reason = await _promptText(
                          context,
                          title: 'Closure reason',
                          label: 'Reason for closing this case',
                        );
                        if (reason == null) return;
                        final notes = await _promptText(
                          context,
                          title: 'Closure notes',
                          label: 'Additional closure documentation',
                        );
                        if (notes == null) return;
                        await _runLifecycleAction(() async {
                          await ref.read(caseLifecycleApiProvider).transitionCaseStatus(
                                caseId: record.caseId,
                                targetStatus: CaseStatus.closed.firestoreValue,
                                closureReason: reason,
                                closureNotes: notes,
                              );
                        });
                      },
              ),
            if (record.caseStatus == CaseStatus.closed)
              AppButton.primary(
                label: 'Reopen case',
                onPressed: _busy
                    ? null
                    : () async {
                        final reopenReason = await _promptText(
                          context,
                          title: 'Reopen case',
                          label: 'Reason for reopening',
                        );
                        if (reopenReason == null) return;
                        await _runLifecycleAction(() async {
                          await ref.read(caseLifecycleApiProvider).transitionCaseStatus(
                                caseId: record.caseId,
                                targetStatus: CaseStatus.inProgress.firestoreValue,
                                reopenReason: reopenReason,
                              );
                        });
                      },
              ),
          ],
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
