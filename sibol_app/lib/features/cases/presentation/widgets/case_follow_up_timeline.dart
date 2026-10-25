import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:sibol_app/features/cases/domain/entities/follow_up_timeline_entry.dart';
import 'package:sibol_app/features/cases/presentation/providers/case_providers.dart';
import 'package:sibol_app/shared/widgets/app_error_widget.dart';
import 'package:sibol_app/shared/widgets/app_loading_indicator.dart';

/// Follow-up list for a case (chronological by scheduledAt).
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
      data: (entries) {
        if (entries.isEmpty) {
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
            for (var i = 0; i < entries.length; i++) ...[
              _FollowUpTile(
                entry: entries[i],
                dateTimeFmt: dateTimeFmt,
              ),
              if (i < entries.length - 1) const Divider(height: 1),
            ],
          ],
        );
      },
    );
  }
}

class _FollowUpTile extends StatelessWidget {
  const _FollowUpTile({
    required this.entry,
    required this.dateTimeFmt,
  });

  final FollowUpTimelineEntry entry;
  final DateFormat dateTimeFmt;

  @override
  Widget build(BuildContext context) {
    final followUp = entry.followUp;
    final notes = followUp.notes.trim();
    final recordedAt = followUp.createdAt ?? followUp.scheduledAt;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  dateTimeFmt.format(recordedAt),
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              if (entry.awaitingServerConfirmation)
                Chip(
                  label: const Text('Pending sync'),
                  visualDensity: VisualDensity.compact,
                  avatar: Icon(
                    Icons.sync,
                    size: 16,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                )
              else if (entry.isFromCache)
                Chip(
                  label: const Text('Cached only'),
                  visualDensity: VisualDensity.compact,
                ),
            ],
          ),
          if (followUp.createdByUid != null &&
              followUp.createdByUid!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'Recorded by staff (${followUp.createdByUid})',
                style: Theme.of(context).textTheme.bodySmall,
              ),
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
