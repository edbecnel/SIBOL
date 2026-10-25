import 'package:flutter/material.dart';

class CachedDataNotice extends StatelessWidget {
  const CachedDataNotice({super.key, required this.isFromCache});

  final bool isFromCache;

  @override
  Widget build(BuildContext context) {
    if (!isFromCache) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(Icons.cloud_off, size: 16, color: Theme.of(context).colorScheme.outline),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              'Showing data from this device — waiting for a server snapshot to '
              'confirm it is up to date.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}
