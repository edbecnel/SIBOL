import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:sibol_app/core/constants/route_constants.dart';
import 'package:sibol_app/features/teenager/domain/assistance_request_submitter_identity.dart';
import 'package:sibol_app/features/teenager/presentation/providers/barangay_assistance_providers.dart';
import 'package:sibol_app/shared/widgets/app_error_widget.dart';
import 'package:sibol_app/shared/widgets/app_loading_indicator.dart';
import 'package:sibol_app/shared/widgets/cached_data_notice.dart';
import 'package:sibol_app/shared/widgets/fictional_data_banner.dart';

class BarangayIncomingRequestsScreen extends ConsumerWidget {
  const BarangayIncomingRequestsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requestsAsync = ref.watch(barangayIncomingRequestsProvider);
    final dateFmt = DateFormat.yMMMd().add_jm();

    return Scaffold(
      appBar: AppBar(title: const Text('Incoming requests')),
      body: Column(
        children: [
          const FictionalDataBanner(),
          Expanded(
            child: requestsAsync.when(
              loading: () => const AppLoadingIndicator(
                message: 'Loading incoming requests…',
              ),
              error: (e, _) => AppErrorWidget(message: e.toString()),
              data: (snapshot) {
                final requests = snapshot.items;
                if (requests.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'No incoming assistance requests for your barangay site.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: requests.length + 1,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return CachedDataNotice(isFromCache: snapshot.isFromCache);
                    }
                    final request = requests[index - 1];
                    return Card(
                      child: ListTile(
                        title: Text(request.category.label),
                        subtitle: Text(
                          '${assistanceIncomingRequestCardAccountEmailLine(request.submitterAccountEmail)}\n'
                          'Ref: ${request.requestId}\n'
                          'Submitted ${dateFmt.format(request.createdAt)}\n'
                          'Status: ${request.status.label}',
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => context.push(
                          Routes.barangayIncomingRequestDetail(request.requestId),
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
