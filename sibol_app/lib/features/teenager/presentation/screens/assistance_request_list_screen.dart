import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:sibol_app/core/constants/route_constants.dart';
import 'package:sibol_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:sibol_app/features/offline/domain/pending_operation.dart';
import 'package:sibol_app/features/offline/presentation/offline_providers.dart';
import 'package:sibol_app/features/teenager/domain/assistance_request_category.dart';
import 'package:sibol_app/features/teenager/presentation/providers/assistance_request_providers.dart';
import 'package:sibol_app/shared/widgets/app_error_widget.dart';
import 'package:sibol_app/shared/widgets/app_loading_indicator.dart';
import 'package:sibol_app/shared/widgets/cached_data_notice.dart';
import 'package:sibol_app/shared/widgets/fictional_data_banner.dart';

class AssistanceRequestListScreen extends ConsumerWidget {
  const AssistanceRequestListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requestsAsync = ref.watch(myAssistanceRequestsProvider);
    final uid = ref.watch(authStateChangesProvider).value?.uid;
    final pendingAsync =
        uid == null ? null : ref.watch(pendingOperationsProvider(uid));
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
              data: (snapshot) {
                final requests = snapshot.items;
                final pendingTeen = (pendingAsync?.asData?.value ??
                        const <PendingOperation>[])
                    .where(
                      (o) => o.kind == PendingOperationKind.teenAssistanceSubmit,
                    )
                    .toList();
                if (requests.isEmpty && pendingTeen.isEmpty) {
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
                  itemCount: pendingTeen.length + requests.length + 1,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return CachedDataNotice(isFromCache: snapshot.isFromCache);
                    }
                    final dataIndex = index - 1;
                    if (dataIndex < pendingTeen.length) {
                      final op = pendingTeen[dataIndex];
                      final category = AssistanceRequestCategory.fromFirestore(
                        op.payload['category'],
                      );
                      return Card(
                        color: Theme.of(context).colorScheme.surfaceContainerHighest,
                        child: ListTile(
                          leading: const Icon(Icons.cloud_off),
                          title: Text(
                            category?.label ?? 'Support request',
                          ),
                          subtitle: Text(
                            'Saved on this device only — not confirmed by your Barangay yet.\n'
                            'Status: ${_pendingLabel(op.state)}',
                          ),
                          isThreeLine: true,
                        ),
                      );
                    }
                    final request = requests[dataIndex - pendingTeen.length];
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

  static String _pendingLabel(PendingOperationState state) {
    switch (state) {
      case PendingOperationState.savedLocally:
        return 'Saved locally';
      case PendingOperationState.waitingToSubmit:
        return 'Waiting to submit';
      case PendingOperationState.submitting:
        return 'Submitting…';
      case PendingOperationState.failedRetryable:
        return 'Waiting to retry';
      case PendingOperationState.failedPermanent:
        return 'Failed — needs attention';
      case PendingOperationState.conflict:
        return 'Conflict — needs attention';
      case PendingOperationState.submittedConfirmed:
        return 'Submitted';
    }
  }
}
