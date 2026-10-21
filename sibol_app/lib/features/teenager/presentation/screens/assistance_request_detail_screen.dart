import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:sibol_app/features/teenager/presentation/providers/assistance_request_providers.dart';
import 'package:sibol_app/features/teenager/presentation/widgets/teen_non_emergency_notice.dart';
import 'package:sibol_app/shared/widgets/app_error_widget.dart';
import 'package:sibol_app/shared/widgets/app_loading_indicator.dart';
import 'package:sibol_app/shared/widgets/fictional_data_banner.dart';

class AssistanceRequestDetailScreen extends ConsumerWidget {
  const AssistanceRequestDetailScreen({super.key, required this.requestId});

  final String requestId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requestAsync = ref.watch(assistanceRequestDetailProvider(requestId));
    final dateFmt = DateFormat.yMMMd().add_jm();

    return Scaffold(
      appBar: AppBar(title: const Text('Request details')),
      body: Column(
        children: [
          const FictionalDataBanner(),
          Expanded(
            child: requestAsync.when(
              loading: () => const AppLoadingIndicator(
                message: 'Loading request…',
              ),
              error: (e, _) => AppErrorWidget(message: e.toString()),
              data: (request) {
                if (request == null) {
                  return const Center(
                    child: Text(
                      'This request was not found or you do not have access.',
                      textAlign: TextAlign.center,
                    ),
                  );
                }
                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    const TeenNonEmergencyNotice(),
                    const SizedBox(height: 16),
                    _DetailRow(label: 'Reference', value: request.requestId),
                    _DetailRow(
                      label: 'Category',
                      value: request.category.label,
                    ),
                    _DetailRow(
                      label: 'Submitted',
                      value: dateFmt.format(request.createdAt),
                    ),
                    _DetailRow(
                      label: 'Status',
                      value: request.status.label,
                    ),
                    if (request.acknowledgedAt != null) ...[
                      _DetailRow(
                        label: 'Acknowledged',
                        value: dateFmt.format(request.acknowledgedAt!),
                      ),
                    ],
                    const SizedBox(height: 16),
                    Text(
                      'Description',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(request.description),
                    const SizedBox(height: 24),
                    Text(
                      'Demonstration prototype: your request can be viewed and acknowledged by '
                      'your assigned barangay. Acknowledgment confirms receipt only; it does not '
                      'mean assistance has been provided.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelLarge,
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
