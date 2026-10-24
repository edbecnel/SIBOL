import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sibol_app/core/errors/user_error_message.dart';
import 'package:sibol_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:sibol_app/shared/widgets/app_button.dart';
import 'package:sibol_app/shared/widgets/app_text_field.dart';

class PasswordResetScreen extends ConsumerStatefulWidget {
  const PasswordResetScreen({super.key});

  @override
  ConsumerState<PasswordResetScreen> createState() => _PasswordResetScreenState();
}

class _PasswordResetScreenState extends ConsumerState<PasswordResetScreen> {
  final _emailController = TextEditingController();
  bool _submitting = false;
  String? _error;
  String? _success;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _submitting = true;
      _error = null;
      _success = null;
    });
    try {
      await ref.read(authControllerProvider.notifier).sendPasswordResetEmail(
            _emailController.text.trim(),
          );
      setState(() => _success = 'If an account exists, a reset email was sent.');
    } catch (e) {
      setState(() => _error = userErrorMessage(e));
    } finally {
      setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reset password')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppTextField(
              controller: _emailController,
              label: 'Email',
              keyboardType: TextInputType.emailAddress,
            ),
            if (_error != null)
              Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            if (_success != null) Text(_success!),
            const Spacer(),
            AppButton.primary(
              label: _submitting ? 'Sending…' : 'Send reset email',
              onPressed: _submitting ? null : _submit,
            ),
            TextButton(
              onPressed: () => context.pop(),
              child: const Text('Back to sign in'),
            ),
          ],
        ),
      ),
    );
  }
}
