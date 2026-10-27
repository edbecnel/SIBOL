import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:sibol_app/shared/widgets/app_text_field.dart';

/// Result of the staff temporary-password form (first step of admin reset).
class StaffPasswordResetFormResult {
  const StaffPasswordResetFormResult(this.password);

  final String password;
}

/// Keyboard-safe password entry for administrative staff password reset.
Future<StaffPasswordResetFormResult?> showStaffPasswordResetFormDialog({
  required BuildContext context,
  required String displayName,
  required String email,
}) {
  return showDialog<StaffPasswordResetFormResult>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      final keyboardInset = MediaQuery.viewInsetsOf(dialogContext).bottom;
      return AnimatedPadding(
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        padding: EdgeInsets.only(bottom: keyboardInset),
        child: StaffPasswordResetFormDialog(
          displayName: displayName,
          email: email,
        ),
      );
    },
  );
}

class StaffPasswordResetFormDialog extends StatefulWidget {
  const StaffPasswordResetFormDialog({
    required this.displayName,
    required this.email,
    super.key,
  });

  final String displayName;
  final String email;

  @override
  State<StaffPasswordResetFormDialog> createState() =>
      _StaffPasswordResetFormDialogState();
}

class _StaffPasswordResetFormDialogState
    extends State<StaffPasswordResetFormDialog> {
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  String? _validationMessage;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _submit() {
    final password = _passwordController.text;
    final confirm = _confirmController.text;
    if (password.length < 8) {
      setState(() {
        _validationMessage = 'Temporary password must be at least 8 characters.';
      });
      return;
    }
    if (password != confirm) {
      setState(() {
        _validationMessage = 'Passwords do not match.';
      });
      return;
    }
    Navigator.of(context).pop(StaffPasswordResetFormResult(password));
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final dialogWidth = math.min(400.0, screenWidth - 32);

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: SizedBox(
        width: dialogWidth,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Reset password',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              Text('Staff member: ${widget.displayName}'),
              Text('Email: ${widget.email}'),
              const SizedBox(height: 16),
              AppTextField(
                key: const Key('staff-reset-temporary-password'),
                controller: _passwordController,
                label: 'Temporary password',
                isPassword: true,
                textInputAction: TextInputAction.next,
                onSubmitted: (_) => FocusScope.of(context).nextFocus(),
              ),
              const SizedBox(height: 12),
              AppTextField(
                key: const Key('staff-reset-confirm-password'),
                controller: _confirmController,
                label: 'Confirm temporary password',
                isPassword: true,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _submit(),
              ),
              if (_validationMessage != null) ...[
                const SizedBox(height: 8),
                Text(
                  _validationMessage!,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              ],
              const SizedBox(height: 20),
              Wrap(
                alignment: WrapAlignment.end,
                spacing: 8,
                runSpacing: 4,
                children: [
                  TextButton(
                    key: const Key('staff-reset-cancel'),
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    key: const Key('staff-reset-continue'),
                    onPressed: _submit,
                    child: const Text('Continue'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
