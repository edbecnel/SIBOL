import 'package:flutter/material.dart';

/// Shown on Teen assistance flows — not an emergency service.
class TeenNonEmergencyNotice extends StatelessWidget {
  const TeenNonEmergencyNotice({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.errorContainer.withValues(alpha: 0.35),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Text(
          'Demonstration only. This is not an operational emergency-response service. '
          'Do not use for real emergencies. All entries must be fictional.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ),
    );
  }
}
