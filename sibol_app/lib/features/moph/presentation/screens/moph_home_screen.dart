import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:sibol_app/core/constants/route_constants.dart';
import 'package:sibol_app/features/coordination/presentation/providers/coordination_providers.dart';
import 'package:sibol_app/features/org/presentation/widgets/organization_directory_display.dart';
import 'package:sibol_app/features/org/presentation/providers/org_context_providers.dart';
import 'package:sibol_app/features/reporting/presentation/providers/report_providers.dart';
import 'package:sibol_app/shared/widgets/app_error_widget.dart';
import 'package:sibol_app/shared/widgets/app_loading_indicator.dart';
import 'package:sibol_app/shared/widgets/fictional_data_banner.dart';

class MophHomeScreen extends ConsumerWidget {
  const MophHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accessAsync = ref.watch(mophOperationalContextProvider);
    final coordinationsAsync = ref.watch(mophCoordinationThreadsProvider);
    final reportsAsync = ref.watch(mophSubmittedReportsProvider);
    final dateFmt = DateFormat.yMMMd();

    return Scaffold(
      appBar: AppBar(
        title: const Text('MOPH dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.push(Routes.settings),
          ),
        ],
      ),
      body: Column(
        children: [
          const FictionalDataBanner(),
          Expanded(
            child: accessAsync.when(
              loading: () => const AppLoadingIndicator(
                message: 'Loading hospital account…',
              ),
              error: (e, _) => AppErrorWidget(message: e.toString()),
              data: (_) => ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  'Individual case coordination',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  'Minimum-information referrals from barangay (not aggregate reports).',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 8),
                coordinationsAsync.when(
                  loading: () => const AppLoadingIndicator(
                    message: 'Loading coordinations…',
                  ),
                  error: (e, _) => AppErrorWidget(message: e.toString()),
                  data: (threads) {
                    if (threads.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Text(
                          'No open coordination referrals yet.',
                        ),
                      );
                    }
                    return Column(
                      children: threads
                          .map(
                            (t) => Card(
                              child: ListTile(
                                title: Text(t.displayRef),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    OrganizationDirectoryNameText(
                                      orgId: t.orgId,
                                    ),
                                    Text(
                                      '${t.category.label} · ${t.phase.label}\n'
                                      'Referred ${dateFmt.format(t.createdAt)}',
                                    ),
                                  ],
                                ),
                                isThreeLine: true,
                                trailing: const Icon(Icons.chevron_right),
                                onTap: () => context.push(
                                  Routes.mophCoordinationDetail(t.threadId),
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    );
                  },
                ),
                const SizedBox(height: 24),
                Text(
                  'Submitted barangay reports',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  'Aggregate summaries only.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 8),
                reportsAsync.when(
                  loading: () => const AppLoadingIndicator(
                    message: 'Loading submitted reports…',
                  ),
                  error: (e, _) => AppErrorWidget(message: e.toString()),
                  data: (reports) {
                    if (reports.isEmpty) {
                      return const Text(
                        'No submitted aggregate reports yet.',
                      );
                    }
                    return Column(
                      children: reports
                          .map(
                            (report) => Card(
                              child: ListTile(
                                title: OrganizationDirectoryNameText(
                                  orgId: report.orgId.isNotEmpty
                                      ? report.orgId
                                      : null,
                                ),
                                subtitle: Text(
                                  'Submitted ${dateFmt.format(report.submittedAt)}\n'
                                  'Cases represented: ${report.totalCaseCount}',
                                ),
                                isThreeLine: true,
                                trailing: const Icon(Icons.chevron_right),
                                onTap: () => context.push(
                                  Routes.mophReportDetail(report.reportId),
                                ),
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
          ),
        ],
      ),
    );
  }
}
