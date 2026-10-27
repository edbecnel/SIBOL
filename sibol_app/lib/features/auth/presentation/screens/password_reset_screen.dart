import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sibol_app/core/errors/user_error_message.dart';
import 'package:sibol_app/features/auth/domain/password_recovery_email.dart';
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
    final validation = PasswordRecoveryEmail.validateForPasswordReset(
      _emailController.text,
    );
    if (validation != null) {
      setState(() {
        _error = validation;
        _success = null;
      });
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
      _success = null;
    });
    try {
      await ref.read(authControllerProvider.notifier).sendPasswordResetEmail(
            _emailController.text.trim(),
          );
      setState(() {
        _success =
            'If an account exists for this address, Firebase sent a password reset email. '
            'Open the link in your inbox (check spam), set a new password, then return here to sign in.';
      });
    } catch (e) {
      setState(() => _error = userErrorMessage(e));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Reset password')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Enter the email you use to sign in. This sends a Firebase Authentication '
              'reset link to your inbox. It is not the same as changing your password while signed in.',
            ),
            const SizedBox(height: 16),
            AppTextField(
              controller: _emailController,
              label: 'Email',
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) {
                if (!_submitting) _submit();
              },
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: TextStyle(color: theme.colorScheme.error),
              ),
            ],
            if (_success != null) ...[
              const SizedBox(height: 12),
              Text(
                _success!,
                style: TextStyle(color: theme.colorScheme.primary),
              ),
            ],
            const Spacer(),
            AppButton.primary(
              label: _submitting ? 'Sending…' : 'Send reset email',
              onPressed: _submitting ? null : _submit,
            ),
            TextButton(
              onPressed: _submitting ? null : () => context.pop(),
              child: const Text('Back to sign in'),
            ),
          ],
        ),
      ),
    );
  }
}
