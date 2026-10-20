import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sibol_app/core/constants/route_constants.dart';
import 'package:sibol_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:sibol_app/shared/widgets/fictional_data_banner.dart';

class TeenHomeScreen extends ConsumerWidget {
  const TeenHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProfileProvider).value;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Teenager dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.push(Routes.settings),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const FictionalDataBanner(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  'Hello, ${profile?.displayName ?? 'demo user'}',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                const Text(
                  'This dashboard demonstrates adolescent health information and support resources. '
                  'It does not create official patient records.',
                ),
                const SizedBox(height: 24),
                _ResourceCard(
                  title: 'Maternal health information',
                  body: 'General education about seeking care from qualified health professionals.',
                ),
                _ResourceCard(
                  title: 'Support resources',
                  body: 'Illustrative links to barangay health services (fictional for demo).',
                ),
                _ResourceCard(
                  title: 'Request for assistance (demo)',
                  body: 'A future tranche may persist illustrative assistance requests. '
                      'Tranche 1 does not store teen-submitted case records.',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ResourceCard extends StatelessWidget {
  const _ResourceCard({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(body),
          ],
        ),
      ),
    );
  }
}
