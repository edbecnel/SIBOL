import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sibol_app/features/coordination/presentation/providers/coordination_providers.dart';
import 'package:sibol_app/features/coordination/presentation/widgets/coordination_thread_detail_body.dart';
import 'package:sibol_app/shared/widgets/app_error_widget.dart';
import 'package:sibol_app/shared/widgets/app_loading_indicator.dart';
import 'package:sibol_app/features/moph/presentation/widgets/moph_coordination_status_panel.dart';
import 'package:sibol_app/shared/widgets/fictional_data_banner.dart';

class MophCoordinationDetailScreen extends ConsumerWidget {
  const MophCoordinationDetailScreen({super.key, required this.threadId});

  final String threadId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final threadAsync = ref.watch(mophCoordinationThreadProvider(threadId));
    final eventsAsync = ref.watch(mophCoordinationStaffEventsProvider(threadId));

    return Scaffold(
      appBar: AppBar(title: const Text('Coordination referral')),
      body: Column(
        children: [
          const FictionalDataBanner(),
          Expanded(
            child: threadAsync.when(
              loading: () => const AppLoadingIndicator(
                message: 'Loading referral…',
              ),
              error: (e, _) => AppErrorWidget(message: e.toString()),
              data: (thread) {
                if (thread == null) {
                  return const Center(
                    child: Text('Referral not found or not available.'),
                  );
                }
                return eventsAsync.when(
                  loading: () => const AppLoadingIndicator(),
                  error: (e, _) => AppErrorWidget(message: e.toString()),
                  data: (events) => ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      MophCoordinationStatusPanel(thread: thread),
                      const SizedBox(height: 16),
                      CoordinationThreadDetailBody(
                        thread: thread,
                        events: events,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
