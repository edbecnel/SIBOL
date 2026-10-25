import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sibol_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:sibol_app/features/offline/presentation/offline_providers.dart';

/// Returns true when sign-out should proceed (no pending work or user confirmed).
Future<bool> confirmSignOutIfPendingOperations(
  BuildContext context,
  WidgetRef ref,
) async {
  final uid = ref.read(authStateChangesProvider).value?.uid;
  if (uid == null) return true;

  final pending = await ref.read(offlineSyncServiceProvider).pendingForUser(uid);
  if (pending.isEmpty) return true;

  if (!context.mounted) return false;
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Unsynced actions on this device'),
      content: Text(
        'You have ${pending.length} action(s) saved on this device that have '
        'not been confirmed by the server. Signing out will keep them for '
        'your account, but they will not sync until you sign back in as the '
        'same user and reconnect.\n\nSign out anyway?',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: const Text('Stay signed in'),
        ),
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          child: const Text('Sign out'),
        ),
      ],
    ),
  );
  return confirmed == true;
}
