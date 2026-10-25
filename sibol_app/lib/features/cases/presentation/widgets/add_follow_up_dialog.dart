import 'package:flutter/material.dart';
import 'package:sibol_app/features/cases/domain/follow_up_validation.dart';

class AddFollowUpDialog extends StatefulWidget {
  const AddFollowUpDialog({super.key});

  @override
  State<AddFollowUpDialog> createState() => _AddFollowUpDialogState();
}

class _AddFollowUpDialogState extends State<AddFollowUpDialog> {
  final _notesController = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  void _save() {
    final error = FollowUpValidation.validateNotes(_notesController.text);
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    Navigator.of(context).pop(_notesController.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add follow-up'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Record what was done, observed, or planned for this fictional case.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Observation or action taken',
                alignLabelWithHint: true,
              ),
              maxLines: 5,
              autofocus: true,
              onChanged: (_) {
                if (_error != null) setState(() => _error = null);
              },
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _save,
          child: const Text('Save'),
        ),
      ],
    );
  }
}
