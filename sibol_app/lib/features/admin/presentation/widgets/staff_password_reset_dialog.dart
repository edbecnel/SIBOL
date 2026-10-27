import 'package:flutter/material.dart';
import 'package:sibol_app/shared/widgets/app_text_field.dart';

/// Result of the staff temporary-password form (first step of admin reset).
class StaffPasswordResetFormResult {
  const StaffPasswordResetFormResult(this.password);

  final String password;
}

/// Keyboard-safe password entry for administrative staff password reset.
///
/// Uses a modal bottom sheet (not [Dialog]) so Android keyboard insets do not
/// collapse the form on narrow devices (e.g. Galaxy S9).
Future<StaffPasswordResetFormResult?> showStaffPasswordResetFormDialog({
  required BuildContext context,
  required String displayName,
  required String email,
}) {
  return showModalBottomSheet<StaffPasswordResetFormResult>(
    context: context,
    isScrollControlled: true,
    isDismissible: false,
    enableDrag: false,
    useSafeArea: true,
    builder: (sheetContext) {
      final bottomInset = MediaQuery.viewInsetsOf(sheetContext).bottom;
      return Padding(
        padding: EdgeInsets.only(bottom: bottomInset),
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
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;

    return Material(
      color: theme.colorScheme.surface,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Reset password',
              style: theme.textTheme.titleLarge?.copyWith(color: onSurface),
            ),
            const SizedBox(height: 12),
            Text(
              'Staff member: ${widget.displayName}',
              style: TextStyle(color: onSurface),
            ),
            Text(
              'Email: ${widget.email}',
              style: TextStyle(color: onSurface),
            ),
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
                style: TextStyle(color: theme.colorScheme.error),
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
    );
  }
}
