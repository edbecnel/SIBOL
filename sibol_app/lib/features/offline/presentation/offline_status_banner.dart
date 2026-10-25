import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sibol_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:sibol_app/features/offline/domain/pending_operation.dart';
import 'package:sibol_app/features/offline/presentation/offline_providers.dart';

class OfflineStatusBanner extends ConsumerStatefulWidget {
  const OfflineStatusBanner({super.key});

  @override
  ConsumerState<OfflineStatusBanner> createState() => _OfflineStatusBannerState();
}

class _OfflineStatusBannerState extends ConsumerState<OfflineStatusBanner> {
  bool _retrying = false;

  static String _kindLabel(PendingOperationKind kind) {
    switch (kind) {
      case PendingOperationKind.teenAssistanceSubmit:
        return 'teen assistance request';
      case PendingOperationKind.barangayAcknowledge:
        return 'request acknowledgment';
      case PendingOperationKind.barangayReferral:
        return 'MOPH referral';
      case PendingOperationKind.barangayReportSubmit:
        return 'barangay report';
    }
  }

  Future<void> _retry(String uid) async {
    setState(() => _retrying = true);
    try {
      final summary =
          await ref.read(offlineSyncServiceProvider).syncForUser(uid);
      ref.invalidate(pendingOperationsProvider(uid));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(summary.userMessage)),
      );
    } finally {
      if (mounted) setState(() => _retrying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = ref.watch(authStateChangesProvider).value?.uid;
    if (uid == null) return const SizedBox.shrink();
    final pending = ref.watch(pendingOperationsProvider(uid));
    return pending.when(
      data: (ops) {
        if (ops.isEmpty) return const SizedBox.shrink();
        final kinds = ops.map((o) => _kindLabel(o.kind)).toSet().join(', ');
        String? errorHint;
        for (final op in ops) {
          final err = op.lastError;
          if (err != null && err.isNotEmpty) {
            errorHint = err;
            break;
          }
        }
        return MaterialBanner(
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${ops.length} action(s) saved on this device awaiting server '
                'confirmation ($kinds).',
              ),
              if (errorHint != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    'Last issue: $errorHint',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
            ],
          ),
          leading: const Icon(Icons.cloud_off),
          actions: [
            TextButton(
              onPressed: _retrying ? null : () => _retry(uid),
              child: _retrying
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Retry now'),
            ),
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
