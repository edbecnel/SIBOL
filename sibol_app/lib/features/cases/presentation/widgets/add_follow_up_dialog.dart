import 'package:flutter/material.dart';
import 'package:sibol_app/features/cases/domain/entities/follow_up.dart';

class AddFollowUpDialogResult {
  const AddFollowUpDialogResult({
    required this.scheduledAt,
    required this.status,
    required this.notes,
    this.completedAt,
  });

  final DateTime scheduledAt;
  final FollowUpStatus status;
  final String notes;
  final DateTime? completedAt;
}

class AddFollowUpDialog extends StatefulWidget {
  const AddFollowUpDialog({super.key});

  @override
  State<AddFollowUpDialog> createState() => _AddFollowUpDialogState();
}

class _AddFollowUpDialogState extends State<AddFollowUpDialog> {
  DateTime _scheduledAt = DateTime.now();
  FollowUpStatus _status = FollowUpStatus.scheduled;
  final _notesController = TextEditingController();

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _scheduledAt,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_scheduledAt),
    );
    if (time == null || !mounted) return;
    setState(() {
      _scheduledAt = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Record follow-up'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            OutlinedButton(
              onPressed: _pickDateTime,
              child: Text('Scheduled: ${_scheduledAt.toLocal()}'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<FollowUpStatus>(
              value: _status,
              decoration: const InputDecoration(labelText: 'Status'),
              items: FollowUpStatus.values
                  .map(
                    (s) => DropdownMenuItem(
                      value: s,
                      child: Text(s.firestoreValue),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) setState(() => _status = value);
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(labelText: 'Notes'),
              maxLines: 3,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            Navigator.of(context).pop(
              AddFollowUpDialogResult(
                scheduledAt: _scheduledAt.toUtc(),
                status: _status,
                notes: _notesController.text.trim(),
                completedAt:
                    _status == FollowUpStatus.completed ? DateTime.now().toUtc() : null,
              ),
            );
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
