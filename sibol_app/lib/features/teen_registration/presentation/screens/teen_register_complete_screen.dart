import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sibol_app/core/constants/route_constants.dart';
import 'package:sibol_app/shared/widgets/app_button.dart';

class TeenRegisterCompleteScreen extends ConsumerWidget {
  const TeenRegisterCompleteScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Registration complete')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Your Teen profile is ready. You can request assistance from your selected Barangay.',
            ),
            const Spacer(),
            AppButton.primary(
              label: 'Go to Teen home',
              onPressed: () => context.go(Routes.teenHome),
            ),
          ],
        ),
      ),
    );
  }
}
