import 'package:flutter/material.dart';

class CaseFirestoreSyncNotice extends StatelessWidget {
  const CaseFirestoreSyncNotice({
    super.key,
    required this.isFromCache,
    required this.hasPendingWrites,
  });

  final bool isFromCache;
  final bool hasPendingWrites;

  @override
  Widget build(BuildContext context) {
    if (!isFromCache && !hasPendingWrites) {
      return const SizedBox.shrink();
    }
    final messages = <String>[];
    if (isFromCache) {
      messages.add('Showing cached case data — reconnect to refresh from the server.');
    }
    if (hasPendingWrites) {
      messages.add(
        'Local changes are saved on this device and will sync when online.',
      );
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                hasPendingWrites ? Icons.sync : Icons.cloud_off,
                size: 20,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  messages.join(' '),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
