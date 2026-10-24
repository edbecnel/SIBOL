import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sibol_app/core/constants/route_constants.dart';
import 'package:sibol_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:sibol_app/shared/widgets/app_button.dart';

class TeenRegisterVerifyEmailScreen extends ConsumerStatefulWidget {
  const TeenRegisterVerifyEmailScreen({super.key});

  @override
  ConsumerState<TeenRegisterVerifyEmailScreen> createState() =>
      _TeenRegisterVerifyEmailScreenState();
}

class _TeenRegisterVerifyEmailScreenState
    extends ConsumerState<TeenRegisterVerifyEmailScreen> {
  DateTime? _lastResend;
  bool _busy = false;
  String? _message;

  Future<void> _resend() async {
    final now = DateTime.now();
    if (_lastResend != null && now.difference(_lastResend!) < const Duration(seconds: 60)) {
      setState(() => _message = 'Please wait before resending.');
      return;
    }
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      await ref.read(authControllerProvider.notifier).sendEmailVerification();
      _lastResend = now;
      setState(() => _message = 'Verification email sent.');
    } catch (e) {
      setState(() => _message = e.toString());
    } finally {
      setState(() => _busy = false);
    }
  }

  Future<void> _refresh() async {
    setState(() => _busy = true);
    try {
      final user = await ref.read(authControllerProvider.notifier).reloadCurrentUser();
      if (user.emailVerified) {
        if (mounted) context.go(Routes.teenRegisterComplete);
      } else {
        setState(() => _message = 'Email not verified yet. Check your inbox.');
      }
    } catch (e) {
      setState(() => _message = e.toString());
    } finally {
      setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Verify email')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Email verification confirms you control this address. '
              'It does not verify age, residence, or eligibility.',
            ),
            if (_message != null) ...[
              const SizedBox(height: 12),
              Text(_message!),
            ],
            const Spacer(),
            AppButton.primary(
              label: _busy ? 'Checking…' : 'I verified — refresh status',
              onPressed: _busy ? null : _refresh,
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: _busy ? null : _resend,
              child: const Text('Resend verification email'),
            ),
          ],
        ),
      ),
    );
  }
}
