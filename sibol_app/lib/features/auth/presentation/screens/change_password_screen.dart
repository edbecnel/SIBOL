import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sibol_app/core/errors/app_exception.dart';
import 'package:sibol_app/core/providers/firebase_providers.dart';
import 'package:sibol_app/core/router/app_redirect.dart';
import 'package:sibol_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:sibol_app/shared/widgets/app_button.dart';
import 'package:sibol_app/shared/widgets/app_text_field.dart';
import 'package:sibol_app/shared/widgets/persistent_success_dialog.dart';

class ChangePasswordScreen extends ConsumerStatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  ConsumerState<ChangePasswordScreen> createState() =>
      _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends ConsumerState<ChangePasswordScreen> {
  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  String? _validate() {
    if (_currentController.text.isEmpty) {
      return 'Enter your current password.';
    }
    if (_newController.text.length < 8) {
      return 'New password must be at least 8 characters.';
    }
    if (_newController.text != _confirmController.text) {
      return 'New passwords do not match.';
    }
    if (_newController.text == _currentController.text) {
      return 'Choose a different password from your current one.';
    }
    return null;
  }

  Future<void> _submit() async {
    final error = _validate();
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
      return;
    }
    setState(() => _submitting = true);
    final mandatory =
        ref.read(userProfileProvider).value?.mustChangePassword ?? false;
    try {
      await ref.read(authRepositoryProvider).changePassword(
            currentPassword: _currentController.text,
            newPassword: _newController.text,
          );
      if (mandatory) {
        await ref.read(authRepositoryProvider).acknowledgeMandatoryPasswordChange();
      }
      if (!mounted) return;
      await showPersistentSuccessDialog(
        context,
        message: 'Your password has been changed successfully.',
      );
      if (!mounted) return;
      if (mandatory) {
        final profile = ref.read(userProfileProvider).value;
        if (profile != null) {
          context.go(homeForProfile(profile));
        } else {
          context.pop();
        }
      } else {
        context.pop();
      }
    } on AuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toFailure().message)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final mandatory =
        ref.watch(userProfileProvider).value?.mustChangePassword ?? false;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Change password'),
        automaticallyImplyLeading: !mandatory,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              mandatory
                  ? 'Your administrator assigned a temporary password. '
                      'Choose a new password before continuing.'
                  : 'Prototype accounts use fictitious email identifiers. '
                      'Email-based password recovery is not available for this demo.',
            ),
            const SizedBox(height: 16),
            AppTextField(
              controller: _currentController,
              label: mandatory ? 'Temporary password' : 'Current password',
              isPassword: true,
            ),
            const SizedBox(height: 12),
            AppTextField(
              controller: _newController,
              label: 'New password',
              isPassword: true,
            ),
            const SizedBox(height: 12),
            AppTextField(
              controller: _confirmController,
              label: 'Confirm new password',
              isPassword: true,
            ),
            const SizedBox(height: 24),
            AppButton.primary(
              label: _submitting ? 'Updating…' : 'Update password',
              onPressed: _submitting ? null : _submit,
            ),
          ],
        ),
      ),
    );
  }
}
