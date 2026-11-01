import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:sibol_app/features/cases/domain/entities/case_record.dart';
import 'package:sibol_app/features/coordination/presentation/providers/coordination_providers.dart';
import 'package:sibol_app/features/disclosure/presentation/providers/disclosure_providers.dart';
import 'package:sibol_app/features/teen_communication/presentation/providers/teen_communication_providers.dart';

class BarangayCaseWorkflowHistoryPanel extends ConsumerWidget {
  const BarangayCaseWorkflowHistoryPanel({
    super.key,
    required this.caseRecord,
  });

  final CaseRecord caseRecord;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final assistanceId = caseRecord.assistanceRequestId;
    if (assistanceId == null || assistanceId.isEmpty) {
      return const SizedBox.shrink();
    }

    final disclosures = ref.watch(
      disclosureAuthorizationsForAssistanceProvider(assistanceId),
    );
    final thread = ref.watch(assistanceCoordinationThreadProvider(assistanceId));
    final teenMessages = ref.watch(teenAssistanceMessagesProvider(assistanceId));
    final dateFmt = DateFormat.yMMMd().add_jm();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Case workflow history',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text('Assistance request: $assistanceId'),
            thread.when(
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
              data: (t) {
                if (t == null) return const Text('Referral: not submitted');
                return Text(
                  'Referral ${t.displayRef} — ${t.coordinationStatus?.label ?? t.phase.label}',
                );
              },
            ),
            const SizedBox(height: 8),
            disclosures.when(
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
              data: (items) {
                if (items.isEmpty) {
                  return const Text('Disclosure authorization: none recorded');
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: items
                      .map(
                        (a) => Text(
                          'Disclosure ${a.authorizationId}: ${a.status}',
                        ),
                      )
                      .toList(),
                );
              },
            ),
            const SizedBox(height: 12),
            Text(
              'Teen-facing communications',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            teenMessages.when(
              loading: () => const Text('Loading communications…'),
              error: (e, _) => Text('$e'),
              data: (messages) {
                if (messages.isEmpty) {
                  return const Text('No teenager communications published yet.');
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: messages
                      .map(
                        (m) => Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            '${dateFmt.format(m.createdAt)} — ${m.displayText}',
                          ),
                        ),
                      )
                      .toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
