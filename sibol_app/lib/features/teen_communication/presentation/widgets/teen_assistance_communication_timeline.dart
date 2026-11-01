import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:sibol_app/features/teen_communication/presentation/providers/teen_communication_providers.dart';

class TeenAssistanceCommunicationTimeline extends ConsumerWidget {
  const TeenAssistanceCommunicationTimeline({
    super.key,
    required this.assistanceRequestId,
  });

  final String assistanceRequestId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final messagesAsync = ref.watch(
      teenAssistanceMessagesProvider(assistanceRequestId),
    );
    final dateFmt = DateFormat.yMMMd().add_jm();

    return messagesAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (e, _) => Text('Could not load updates: $e'),
      data: (messages) {
        if (messages.isEmpty) {
          return const SizedBox.shrink();
        }
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Updates from your Barangay',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                ...messages.map(
                  (m) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          m.sourceLabel,
                          style: Theme.of(context).textTheme.labelMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(m.displayText),
                        const SizedBox(height: 4),
                        Text(
                          dateFmt.format(m.createdAt),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
