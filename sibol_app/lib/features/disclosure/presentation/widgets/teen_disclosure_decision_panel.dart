import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sibol_app/features/disclosure/data/disclosure_api.dart';
import 'package:sibol_app/features/disclosure/domain/disclosure_constants.dart';
import 'package:sibol_app/features/disclosure/presentation/providers/disclosure_providers.dart';
import 'package:sibol_app/shared/widgets/app_button.dart';

class TeenDisclosureDecisionPanel extends ConsumerWidget {
  const TeenDisclosureDecisionPanel({super.key, required this.assistanceRequestId});

  final String assistanceRequestId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pending = ref.watch(teenPendingDisclosureAuthorizationsProvider);
    final progress = ref.watch(
      teenCoordinationLinkForAssistanceProvider(assistanceRequestId),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        pending.when(
          loading: () => const SizedBox.shrink(),
          error: (e, _) => Text('$e'),
          data: (items) {
            final forRequest =
                items.where((a) => a.assistanceRequestId == assistanceRequestId);
            if (forRequest.isEmpty) return const SizedBox.shrink();
            final auth = forRequest.first;
            return Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hospital disclosure authorization',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Your barangay requests permission to share: '
                      '${auth.requestedCategories.join(', ')} with Misamis '
                      'Oriental Provincial Hospital for coordination.',
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () => _decide(
                              context,
                              ref,
                              auth.authorizationId,
                              'declined',
                            ),
                            child: const Text('Decline'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: AppButton.primary(
                            label: 'Approve',
                            onPressed: DisclosureLegalPolicy
                                    .identifyingDisclosureActivated
                                ? () => _decide(
                                      context,
                                      ref,
                                      auth.authorizationId,
                                      'approved',
                                    )
                                : () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Authorized identifying disclosure is not '
                                          'legally activated on this build.',
                                        ),
                                      ),
                                    );
                                  },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        progress.when(
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
          data: (link) {
            if (link == null) return const SizedBox.shrink();
            final label = link['progressLabel'] as String? ?? 'Coordination update';
            return Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Text('Progress: $label'),
            );
          },
        ),
      ],
    );
  }

  Future<void> _decide(
    BuildContext context,
    WidgetRef ref,
    String authorizationId,
    String decision,
  ) async {
    try {
      await ref.read(disclosureApiProvider).recordDecision(
            authorizationId: authorizationId,
            decision: decision,
          );
      ref.invalidate(teenPendingDisclosureAuthorizationsProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Decision recorded: $decision')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e')),
        );
      }
    }
  }
}
