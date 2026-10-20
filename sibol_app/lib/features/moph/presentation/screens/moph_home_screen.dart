import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sibol_app/core/constants/route_constants.dart';
import 'package:sibol_app/shared/widgets/fictional_data_banner.dart';

class MophHomeScreen extends ConsumerWidget {
  const MophHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MOPH dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.push(Routes.settings),
          ),
        ],
      ),
      body: Column(
        children: [
          const FictionalDataBanner(),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Tranche 1 placeholder: accepted demonstration reports will appear here after '
                'the server-authoritative submit workflow is implemented in Tranche 2. '
                'Security rules prevent MOPH from reading barangay case drafts or unsubmitted data.',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
