import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:sibol_app/features/cases/domain/entities/follow_up.dart';
import 'package:sibol_app/features/cases/presentation/providers/case_providers.dart';
import 'package:sibol_app/shared/widgets/app_error_widget.dart';
import 'package:sibol_app/shared/widgets/app_loading_indicator.dart';

/// Read-only follow-up list for a case (T2-2).
///
/// Ordering: ascending by [FollowUp.scheduledAt] (matches Firestore query in
/// [CaseRepositoryImpl.watchFollowUps]).
class CaseFollowUpTimeline extends ConsumerWidget {
  const CaseFollowUpTimeline({super.key, required this.caseId});

  final String caseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final followUpsAsync = ref.watch(followUpsStreamProvider(caseId));
    final dateTimeFmt = DateFormat.yMMMd().add_jm();

    return followUpsAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: AppLoadingIndicator(message: 'Loading follow-ups…'),
      ),
      error: (e, _) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: AppErrorWidget(
          message: 'Could not load follow-ups. ${e.toString()}',
        ),
      ),
      data: (followUps) {
        if (followUps.isEmpty) {
          return Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 16),
            child: Text(
              'No follow-ups recorded for this case.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < followUps.length; i++) ...[
              _FollowUpTile(
                followUp: followUps[i],
                dateTimeFmt: dateTimeFmt,
              ),
              if (i < followUps.length - 1) const Divider(height: 1),
            ],
          ],
        );
      },
    );
  }
}

class _FollowUpTile extends StatelessWidget {
  const _FollowUpTile({
    required this.followUp,
    required this.dateTimeFmt,
  });

  final FollowUp followUp;
  final DateFormat dateTimeFmt;

  @override
  Widget build(BuildContext context) {
    final notes = followUp.notes.trim();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            dateTimeFmt.format(followUp.scheduledAt),
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 4),
          Text('Status: ${followUp.status.firestoreValue}'),
          if (followUp.completedAt != null)
            Text(
              'Completed: ${dateTimeFmt.format(followUp.completedAt!)}',
            ),
          if (notes.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(notes),
          ],
        ],
      ),
    );
  }
}
