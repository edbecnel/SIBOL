import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sibol_app/features/coordination/presentation/providers/coordination_providers.dart';
import 'package:sibol_app/features/coordination/presentation/widgets/barangay_coordination_response_panel.dart';
import 'package:sibol_app/features/coordination/presentation/widgets/coordination_thread_detail_body.dart';
import 'package:sibol_app/shared/widgets/app_error_widget.dart';
import 'package:sibol_app/shared/widgets/app_loading_indicator.dart';
import 'package:sibol_app/shared/widgets/fictional_data_banner.dart';

class BarangayCoordinationDetailScreen extends ConsumerWidget {
  const BarangayCoordinationDetailScreen({super.key, required this.threadId});

  final String threadId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final threadAsync = ref.watch(barangayCoordinationThreadProvider(threadId));
    final eventsAsync =
        ref.watch(barangayCoordinationStaffEventsProvider(threadId));

    return Scaffold(
      appBar: AppBar(title: const Text('Submitted referral')),
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
                    child: Text(
                      'This referral was not found or is not assigned to your '
                      'barangay site.',
                      textAlign: TextAlign.center,
                    ),
                  );
                }
                return eventsAsync.when(
                  loading: () => const AppLoadingIndicator(),
                  error: (e, _) => AppErrorWidget(message: e.toString()),
                  data: (events) => ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      BarangayCoordinationResponsePanel(thread: thread),
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
