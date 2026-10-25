import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sibol_app/config/app_config.dart';
import 'package:sibol_app/core/constants/route_constants.dart';
import 'package:sibol_app/features/admin/presentation/providers/admin_providers.dart';
import 'package:sibol_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:sibol_app/features/auth/presentation/sign_out_pending_guard.dart';
import 'package:sibol_app/shared/widgets/app_button.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProfileProvider).value;
    final authUser = ref.watch(authStateChangesProvider).value;
    final isCentral = ref.watch(isCentralAdminProvider);
    final orgAdminOrgIds = ref.watch(orgAdminManagedOrgIdsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('${AppConfig.appName} v${AppConfig.appVersion}'),
            const SizedBox(height: 16),
            Text('Email: ${authUser?.email ?? '—'}'),
            Text('Role: ${profile?.role.displayLabel ?? '—'}'),
            if (isCentral) ...[
              const SizedBox(height: 16),
              AppButton.primary(
                label: 'Central administration',
                onPressed: () => context.push(Routes.centralAdminOrganizations),
              ),
            ],
            if (orgAdminOrgIds.isNotEmpty) ...[
              const SizedBox(height: 12),
              AppButton.primary(
                label: 'Organization staff administration',
                onPressed: () =>
                    context.push(Routes.orgAdminStaff(orgAdminOrgIds.first)),
              ),
            ],
            const SizedBox(height: 12),
            AppButton.primary(
              label: 'Pending invitations',
              onPressed: () => context.push(Routes.myInvitations),
            ),
            const Spacer(),
            AppButton.primary(
              label: 'Sign out',
              onPressed: () async {
                if (!await confirmSignOutIfPendingOperations(context, ref)) {
                  return;
                }
                await ref.read(authControllerProvider.notifier).signOut();
                if (context.mounted) context.pop();
              },
            ),
          ],
        ),
      ),
    );
  }
}
