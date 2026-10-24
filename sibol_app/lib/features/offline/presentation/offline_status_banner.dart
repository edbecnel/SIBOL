import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sibol_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:sibol_app/features/offline/presentation/offline_providers.dart';

class OfflineStatusBanner extends ConsumerWidget {
  const OfflineStatusBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uid = ref.watch(authStateChangesProvider).value?.uid;
    if (uid == null) return const SizedBox.shrink();
    final pending = ref.watch(pendingOperationsProvider(uid));
    return pending.when(
      data: (ops) {
        if (ops.isEmpty) return const SizedBox.shrink();
        return MaterialBanner(
          content: Text(
            '${ops.length} action(s) saved on this device awaiting server confirmation.',
          ),
          leading: const Icon(Icons.cloud_off),
          actions: [
            TextButton(
              onPressed: () =>
                  ref.read(offlineSyncServiceProvider).syncForUser(uid),
              child: const Text('Retry now'),
            ),
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
