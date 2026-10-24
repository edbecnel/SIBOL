import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sibol_app/core/constants/route_constants.dart';
import 'package:sibol_app/features/auth/presentation/providers/auth_providers.dart';
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
              'Barangay, hospital, and administrator accounts are created through '
              'authorized invitation or provisioning—not Teen self-registration.',
            ),
            const SizedBox(height: 24),
            AppButton.primary(
              label: authOp.isLoading ? 'Signing out…' : 'Sign out',
              onPressed: authOp.isLoading
                  ? null
                  : () async {
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
