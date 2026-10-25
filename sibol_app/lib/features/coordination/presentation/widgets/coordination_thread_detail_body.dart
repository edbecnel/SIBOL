import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:sibol_app/features/coordination/domain/entities/coordination_staff_event.dart';
import 'package:sibol_app/features/coordination/domain/entities/coordination_thread.dart';
import 'package:sibol_app/features/org/presentation/widgets/organization_directory_display.dart';

class CoordinationThreadDetailBody extends ConsumerWidget {
  const CoordinationThreadDetailBody({
    super.key,
    required this.thread,
    required this.events,
  });

  final CoordinationThread thread;
  final List<CoordinationStaffEvent> events;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dateFmt = DateFormat.yMMMd().add_jm();
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Individual case coordination (minimum information). Teen identity '
          'and original request text are not shown.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 16),
        _Row(label: 'Reference', value: thread.displayRef),
        OrganizationIdentityDetailRows(
          orgId: thread.orgId,
          historicalSiteLabel: thread.barangay,
        ),
        _Row(label: 'Category', value: thread.category.label),
        _Row(label: 'Phase', value: thread.phase.label),
        _Row(
          label: 'Referred',
          value: dateFmt.format(thread.createdAt),
        ),
        const SizedBox(height: 16),
        Text(
          'Barangay-prepared summary',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        Text(thread.barangayReferralSummary),
        const SizedBox(height: 24),
        Text(
          'Staff activity',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        if (events.isEmpty)
          const Text('No staff events recorded yet.')
        else
          ...events.map(
            (e) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${e.eventType} · ${dateFmt.format(e.createdAt)}',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  const SizedBox(height: 4),
                  Text(e.body),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(label, style: Theme.of(context).textTheme.labelLarge),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
