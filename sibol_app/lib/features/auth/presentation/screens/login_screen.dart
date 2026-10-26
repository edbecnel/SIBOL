import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sibol_app/core/constants/route_constants.dart';
import 'package:sibol_app/config/app_config.dart';
import 'package:sibol_app/core/errors/user_error_message.dart';
import 'package:sibol_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:sibol_app/shared/widgets/app_button.dart';
import 'package:sibol_app/shared/widgets/app_text_field.dart';
import 'package:sibol_app/shared/widgets/fictional_data_banner.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(authControllerProvider.notifier).clearSignInError();
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    await ref.read(authControllerProvider.notifier).signIn(
          _emailController.text,
          _passwordController.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    final authOp = ref.watch(authControllerProvider);
    final error = authOp.error;

    return Scaffold(
      appBar: AppBar(
        title: const Text('${AppConfig.appName} — Sign in'),
        leading: BackButton(
          onPressed: () {
            ref.read(authControllerProvider.notifier).clearSignInError();
            context.go(Routes.welcome);
          },
        ),
      ),
      body: Column(
        children: [
          const FictionalDataBanner(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Image.asset(
                    'assets/images/sibol_logo.png',
                    height: 72,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                  ),
                  const SizedBox(height: 24),
                  AppTextField(
                    controller: _emailController,
                    label: 'Email',
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 12),
                  AppTextField(
                    controller: _passwordController,
                    label: 'Password',
                    isPassword: true,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _submit(),
                  ),
                  if (error != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      userErrorMessage(error),
                      style: TextStyle(color: Theme.of(context).colorScheme.error),
                    ),
                  ],
                  const SizedBox(height: 24),
                  AppButton.primary(
                    label: 'Sign in',
                    isLoading: authOp.isLoading,
                    onPressed: _submit,
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => context.push(Routes.passwordReset),
                    child: const Text('Forgot password?'),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Use demonstration accounts provisioned by the seed script. '
                    'See shared/docs/DEMO_ACCOUNTS.md.',
                    style: Theme.of(context).textTheme.bodySmall,
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
