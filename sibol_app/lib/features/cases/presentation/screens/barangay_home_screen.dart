import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:sibol_app/core/constants/route_constants.dart';
import 'package:sibol_app/features/admin/presentation/providers/admin_providers.dart';
import 'package:sibol_app/features/cases/presentation/providers/case_providers.dart';
import 'package:sibol_app/features/org/presentation/providers/org_context_providers.dart';
import 'package:sibol_app/shared/widgets/app_loading_indicator.dart';
import 'package:sibol_app/shared/widgets/fictional_data_banner.dart';

class BarangayHomeScreen extends ConsumerWidget {
  const BarangayHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canManageOrg = ref.watch(orgAdminManagedOrgIdsProvider).isNotEmpty;
    final canReadCases = ref.watch(barangayCanReadCasesProvider);
    final canWriteCases = ref.watch(barangayCanWriteCasesProvider);
    final canAssistance = ref.watch(barangayCanAccessAssistanceInboxProvider);
    final canSubmitReport = ref.watch(barangayCanSubmitReportsProvider);
    final orgAdminOrgIds = ref.watch(orgAdminManagedOrgIdsProvider);

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
      floatingActionButton: canWriteCases
          ? FloatingActionButton.extended(
              onPressed: () => context.push(Routes.barangayCaseCreate),
              icon: const Icon(Icons.add),
              label: const Text('New case'),
            )
          : null,
      body: Column(
          children: [
            const FictionalDataBanner(),
            if (canManageOrg) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Organization administration',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Invite staff, approve memberships, and assign operational '
                          'capabilities for your Barangay organization.',
                        ),
                        const SizedBox(height: 12),
                        FilledButton.icon(
                          onPressed: () => context.push(
                            Routes.orgAdminStaff(orgAdminOrgIds.first),
                          ),
                          icon: const Icon(Icons.groups_outlined),
                          label: const Text('Staff administration'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (canReadCases ||
                      canAssistance ||
                      canSubmitReport) ...[
                    Text(
                      'Operational services',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 8),
                  ],
                  _OperationalActionButton(
                    enabled: canAssistance,
                    icon: Icons.inbox,
                    label: 'Incoming requests',
                    disabledHint:
                        'Requires coordination.barangay on your Barangay membership.',
                    onPressed: () => context.push(Routes.barangayIncomingRequests),
                  ),
                  const SizedBox(height: 8),
                  _OperationalActionButton(
                    enabled: canSubmitReport,
                    icon: Icons.upload_file,
                    label: 'Submit report to MOPH',
                    disabledHint:
                        'Requires report.submit on your Barangay membership.',
                    onPressed: () => context.push(Routes.barangaySubmitReport),
                  ),
                  const SizedBox(height: 8),
                  _OperationalActionButton(
                    enabled: canSubmitReport,
                    icon: Icons.history,
                    label: 'Submitted reports',
                    disabledHint:
                        'Requires report.submit on your Barangay membership.',
                    onPressed: () =>
                        context.push(Routes.barangaySubmittedReports),
                  ),
                  const SizedBox(height: 8),
                  _OperationalActionButton(
                    enabled: canAssistance,
                    icon: Icons.medical_services_outlined,
                    label: 'Submitted referrals',
                    disabledHint:
                        'Requires coordination.barangay on your Barangay membership.',
                    onPressed: () =>
                        context.push(Routes.barangaySubmittedReferrals),
                  ),
                ],
              ),
            ),
            Expanded(
              child: canReadCases
                  ? const _BarangayCaseListSection()
                  : _OperationalUnavailablePanel(
                      canManageOrg: canManageOrg,
                    ),
            ),
          ],
        ),
    );
  }
}

class _OperationalActionButton extends StatelessWidget {
  const _OperationalActionButton({
    required this.enabled,
    required this.icon,
    required this.label,
    required this.disabledHint,
    required this.onPressed,
  });

  final bool enabled;
  final IconData icon;
  final String label;
  final String disabledHint;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: enabled ? label : disabledHint,
      child: OutlinedButton.icon(
        onPressed: enabled ? onPressed : null,
        icon: Icon(icon),
        label: Text(label),
      ),
    );
  }
}

class _OperationalUnavailablePanel extends StatelessWidget {
  const _OperationalUnavailablePanel({required this.canManageOrg});

  final bool canManageOrg;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          canManageOrg
              ? 'Operational case access is not assigned to this account. '
                  'An organization administrator can grant case.read and related '
                  'capabilities through staff administration.'
              : 'Operational case access is not authorized for this account. '
                  'Contact your organization administrator.',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class _BarangayCaseListSection extends ConsumerWidget {
  const _BarangayCaseListSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final casesAsync = ref.watch(casesStreamProvider);
    final dateFmt = DateFormat.yMMMd();

    return casesAsync.when(
      loading: () =>
          const AppLoadingIndicator(message: 'Loading fictional cases…'),
      error: (e, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Unable to load cases. If this persists, sign out and sign in again.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
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
    );
  }
}
