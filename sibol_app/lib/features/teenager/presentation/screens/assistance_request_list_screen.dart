import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:sibol_app/core/constants/route_constants.dart';
import 'package:sibol_app/features/teenager/presentation/providers/assistance_request_providers.dart';
import 'package:sibol_app/shared/widgets/app_error_widget.dart';
import 'package:sibol_app/shared/widgets/app_loading_indicator.dart';
import 'package:sibol_app/shared/widgets/fictional_data_banner.dart';

class AssistanceRequestListScreen extends ConsumerWidget {
  const AssistanceRequestListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requestsAsync = ref.watch(myAssistanceRequestsProvider);
    final dateFmt = DateFormat.yMMMd().add_jm();

    return Scaffold(
      appBar: AppBar(title: const Text('My requests')),
      body: Column(
        children: [
          const FictionalDataBanner(),
          Expanded(
            child: requestsAsync.when(
              loading: () => const AppLoadingIndicator(
                message: 'Loading your requests…',
              ),
              error: (e, _) => AppErrorWidget(message: e.toString()),
              data: (requests) {
                if (requests.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'No assistance requests yet. Tap “New support request” on the dashboard to submit a fictional demo request.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: requests.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final request = requests[index];
                    return Card(
                      child: ListTile(
                        title: Text(request.category.label),
                        subtitle: Text(
                          'Ref: ${request.requestId}\n'
                          'Submitted ${dateFmt.format(request.createdAt)}\n'
                          'Status: ${request.status.label}',
                        ),
                        isThreeLine: true,
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => context.push(
                          Routes.teenAssistanceDetail(request.requestId),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
