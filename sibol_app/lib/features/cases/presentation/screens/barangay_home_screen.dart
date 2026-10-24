import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:sibol_app/core/constants/route_constants.dart';
import 'package:sibol_app/features/cases/presentation/providers/case_providers.dart';
import 'package:sibol_app/shared/widgets/app_error_widget.dart';
import 'package:sibol_app/shared/widgets/app_loading_indicator.dart';
import 'package:sibol_app/shared/widgets/fictional_data_banner.dart';

class BarangayHomeScreen extends ConsumerWidget {
  const BarangayHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final casesAsync = ref.watch(casesStreamProvider);
    final dateFmt = DateFormat.yMMMd();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Barangay dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.push(Routes.settings),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(Routes.barangayCaseCreate),
        icon: const Icon(Icons.add),
        label: const Text('New case'),
      ),
      body: Column(
        children: [
          const FictionalDataBanner(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                OutlinedButton.icon(
                  onPressed: () => context.push(Routes.barangayIncomingRequests),
                  icon: const Icon(Icons.inbox),
                  label: const Text('Incoming requests'),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () => context.push(Routes.barangaySubmitReport),
                  icon: const Icon(Icons.upload_file),
                  label: const Text('Submit report to MOPH'),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () => context.push(Routes.barangaySubmittedReports),
                  icon: const Icon(Icons.history),
                  label: const Text('Submitted reports'),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () => context.push(Routes.barangaySubmittedReferrals),
                  icon: const Icon(Icons.medical_services_outlined),
                  label: const Text('Submitted referrals'),
                ),
              ],
            ),
          ),
          Expanded(
            child: casesAsync.when(
              loading: () => const AppLoadingIndicator(message: 'Loading fictional cases…'),
              error: (e, _) => AppErrorWidget(message: e.toString()),
              data: (cases) {
                if (cases.isEmpty) {
                  return const Center(
                    child: Text(
                      'No demonstration cases yet. Run the seed script after Firebase is configured.',
                      textAlign: TextAlign.center,
                    ),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: cases.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final caseRecord = cases[index];
                    return Card(
                      child: ListTile(
                        title: Text(caseRecord.demoName),
                        subtitle: Text(
                          'Age ${caseRecord.age} · ${caseRecord.caseStatus.firestoreValue}\n'
                          'Registered ${dateFmt.format(caseRecord.registeredAt)} · '
                          'Report: ${caseRecord.reportStatus.firestoreValue}',
                        ),
                        isThreeLine: true,
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => context.push(
                          Routes.barangayCaseDetail(caseRecord.caseId),
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
