import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sibol_app/features/org/presentation/providers/organization_directory_providers.dart';

/// Resolves and displays a canonical organization name from [organizationDirectory].
class OrganizationDirectoryNameText extends ConsumerWidget {
  const OrganizationDirectoryNameText({
    super.key,
    required this.orgId,
    this.style,
    this.unavailableLabel = 'Organization name unavailable',
  });

  final String? orgId;
  final TextStyle? style;
  final String unavailableLabel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id = orgId?.trim();
    if (id == null || id.isEmpty) {
      return Text(unavailableLabel, style: style);
    }
    final entryAsync = ref.watch(organizationDirectoryEntryProvider(id));
    return entryAsync.when(
      loading: () => Text('Loading organization…', style: style),
      error: (_, __) => Text(unavailableLabel, style: style),
      data: (entry) => Text(
        entry?.name ?? unavailableLabel,
        style: style,
      ),
    );
  }
}

class OrganizationIdentityDetailRows extends ConsumerWidget {
  const OrganizationIdentityDetailRows({
    super.key,
    required this.orgId,
    this.historicalSiteLabel,
    this.showGeographicSite = true,
  });

  final String? orgId;
  final String? historicalSiteLabel;
  final bool showGeographicSite;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id = orgId?.trim();
    if (id == null || id.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Row(
            label: 'Barangay organization',
            value: 'Organization identity unavailable',
          ),
          if (showGeographicSite &&
              historicalSiteLabel != null &&
              historicalSiteLabel!.trim().isNotEmpty)
            _Row(
              label: 'Historical site label',
              value: historicalSiteLabel!.trim(),
            ),
        ],
      );
    }

    final entryAsync = ref.watch(organizationDirectoryEntryProvider(id));
    return entryAsync.when(
      loading: () => const Text('Loading organization…'),
      error: (_, __) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _Row(
            label: 'Barangay organization',
            value: 'Organization name unavailable',
          ),
          if (showGeographicSite &&
              historicalSiteLabel != null &&
              historicalSiteLabel!.trim().isNotEmpty)
            _Row(
              label: 'Historical site label',
              value: historicalSiteLabel!.trim(),
            ),
        ],
      ),
      data: (entry) {
        final site = entry?.geographicSiteLabel?.trim();
        final historical = historicalSiteLabel?.trim();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Row(
              label: 'Barangay organization',
              value: entry?.name ?? 'Organization name unavailable',
            ),
            if (showGeographicSite) ...[
              if (site != null && site.isNotEmpty)
                _Row(label: 'Geographic site', value: site)
              else if (historical != null && historical.isNotEmpty)
                _Row(label: 'Historical site label', value: historical),
            ],
          ],
        );
      },
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
            width: 150,
            child: Text(label, style: Theme.of(context).textTheme.labelLarge),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
