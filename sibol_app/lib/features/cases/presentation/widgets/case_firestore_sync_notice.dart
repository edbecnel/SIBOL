import 'package:flutter/material.dart';
import 'package:sibol_app/features/cases/domain/case_presentation_labels.dart';

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
    final syncLabel = CasePresentationLabels.synchronizationStatus(
      isFromCache: isFromCache,
      hasPendingWrites: hasPendingWrites,
    );
    if (syncLabel == null || syncLabel == 'Server confirmed') {
      return const SizedBox.shrink();
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
                  syncLabel,
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
