import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sibol_app/core/constants/route_constants.dart';
import 'package:sibol_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:sibol_app/features/auth/presentation/sign_out_pending_guard.dart';
import 'package:sibol_app/features/teen_registration/presentation/providers/teen_registration_intent_providers.dart';
import 'package:sibol_app/shared/widgets/app_button.dart';

/// Signed-in Firebase user without a server `users/{uid}` profile (staff must be provisioned).
class AccountNotProvisionedScreen extends ConsumerWidget {
  const AccountNotProvisionedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authOp = ref.watch(authControllerProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Account not ready')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Your sign-in was recognized, but no SIBOL user profile is available yet. '
              'If you were registering as a Teen, continue registration below. '
              'Staff and administrator accounts are created through authorized provisioning.',
            ),
            const SizedBox(height: 16),
            AppButton.primary(
              label: 'Continue Teen registration',
              onPressed: () async {
                await ref
                    .read(teenRegistrationIntentProvider.notifier)
                    .markInProgress();
                if (context.mounted) context.go(Routes.teenRegister);
              },
            ),
            const SizedBox(height: 12),
            AppButton.primary(
              label: authOp.isLoading ? 'Signing out…' : 'Sign out',
              onPressed: authOp.isLoading
                  ? null
                  : () async {
                      if (!await confirmSignOutIfPendingOperations(context, ref)) {
                        return;
                      }
                      await ref.read(authControllerProvider.notifier).signOut();
                      if (context.mounted) context.go(Routes.welcome);
                    },
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => context.go(Routes.welcome),
              child: const Text('Back to Welcome'),
            ),
          ],
        ),
      ),
    );
  }
}
