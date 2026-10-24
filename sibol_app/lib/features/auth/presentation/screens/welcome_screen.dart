import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sibol_app/config/app_config.dart';
import 'package:sibol_app/core/constants/route_constants.dart';
import 'package:sibol_app/shared/widgets/app_button.dart';
import 'package:sibol_app/shared/widgets/fictional_data_banner.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const FictionalDataBanner(),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Image.asset(
                    'assets/images/sibol_logo.png',
                    height: 120,
                    errorBuilder: (_, __, ___) =>
                        Icon(Icons.spa, size: 120, color: Theme.of(context).colorScheme.primary),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Welcome to ${AppConfig.appName}',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Demonstration prototype for Barangay assistance routing. '
                    'Sign in with a provisioned account or register as a Teen.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 40),
                  AppButton.primary(
                    label: 'Sign in',
                    onPressed: () => context.push(Routes.login),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: () => context.push(Routes.teenRegister),
                    child: const Text('Register as Teen'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
