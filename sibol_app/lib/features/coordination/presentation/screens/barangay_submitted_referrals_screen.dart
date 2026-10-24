import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:sibol_app/core/constants/route_constants.dart';
import 'package:sibol_app/features/coordination/presentation/providers/coordination_providers.dart';
import 'package:sibol_app/shared/widgets/app_error_widget.dart';
import 'package:sibol_app/shared/widgets/app_loading_indicator.dart';
import 'package:sibol_app/shared/widgets/fictional_data_banner.dart';

class BarangaySubmittedReferralsScreen extends ConsumerWidget {
  const BarangaySubmittedReferralsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final referralsAsync = ref.watch(barangaySubmittedReferralsProvider);
    final dateFmt = DateFormat.yMMMd();

    return Scaffold(
      appBar: AppBar(title: const Text('Submitted referrals')),
      body: Column(
        children: [
          const FictionalDataBanner(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Text(
              'MOPH coordination referrals submitted from your barangay site '
              '(minimum information; active and closed).',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          Expanded(
            child: referralsAsync.when(
              loading: () => const AppLoadingIndicator(
                message: 'Loading submitted referrals…',
              ),
              error: (e, _) => AppErrorWidget(message: e.toString()),
              data: (threads) {
                if (threads.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'No submitted referrals yet. After you acknowledge an '
                        'incoming teen request, use Refer to MOPH coordination '
                        'on the request detail screen.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: threads.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final thread = threads[index];
                    return Card(
                      child: ListTile(
                        title: Text(thread.displayRef),
                        subtitle: Text(
                          '${thread.category.label} · ${thread.phase.label}\n'
                          'Last activity ${dateFmt.format(thread.lastStaffEventAt)}',
                        ),
                        isThreeLine: true,
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => context.push(
                          Routes.barangaySubmittedReferralDetail(thread.threadId),
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
