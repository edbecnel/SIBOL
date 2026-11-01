import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sibol_app/features/coordination/domain/entities/coordination_thread.dart';
import 'package:sibol_app/features/coordination/presentation/providers/coordination_providers.dart';
import 'package:sibol_app/features/teen_communication/presentation/providers/teen_communication_providers.dart';
import 'package:sibol_app/shared/widgets/app_button.dart';

class BarangayTeenCommunicationPanel extends ConsumerStatefulWidget {
  const BarangayTeenCommunicationPanel({
    super.key,
    required this.assistanceRequestId,
    required this.coordinationThread,
  });

  final String assistanceRequestId;
  final CoordinationThread? coordinationThread;

  @override
  ConsumerState<BarangayTeenCommunicationPanel> createState() =>
      _BarangayTeenCommunicationPanelState();
}

class _BarangayTeenCommunicationPanelState
    extends ConsumerState<BarangayTeenCommunicationPanel> {
  bool _busy = false;
  String? _error;

  Future<void> _publishProgress() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final key =
          'progress-${widget.assistanceRequestId}-${DateTime.now().millisecondsSinceEpoch}';
      await ref.read(teenCommunicationApiProvider).publishProgressUpdate(
            assistanceRequestId: widget.assistanceRequestId,
            templateCode: 'coordination_progress_generic',
            idempotencyKey: key,
          );
      ref.invalidate(teenAssistanceMessagesProvider(widget.assistanceRequestId));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Progress update sent to teenager.')),
        );
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _confirmOutcome({bool followUp = false}) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final key = 'outcome-${widget.assistanceRequestId}';
      await ref.read(teenCommunicationApiProvider).confirmCoordinationOutcome(
            assistanceRequestId: widget.assistanceRequestId,
            idempotencyKey: key,
            includeFollowUp: followUp,
          );
      ref.invalidate(teenAssistanceMessagesProvider(widget.assistanceRequestId));
      ref.invalidate(
        assistanceCoordinationThreadProvider(widget.assistanceRequestId),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Outcome update published to teenager.'),
          ),
        );
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final thread = widget.coordinationThread;
    final terminal = thread != null && thread.isTerminal;
    final pendingOutcome = thread?.pendingTeenOutcomePublication == true &&
        thread?.teenOutcomeConfirmedAt == null;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Teenager communication',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            const Text(
              'Structured, privacy-safe updates only. Hospital internal notes '
              'are never sent to the teenager.',
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const SizedBox(height: 12),
            AppButton.primary(
              label: 'Send coordination progress update',
              isLoading: _busy,
              onPressed: _busy || thread == null ? null : _publishProgress,
            ),
            if (terminal && pendingOutcome) ...[
              const SizedBox(height: 12),
              const Text(
                'Hospital coordination reached a final outcome. Review before '
                'publishing to the teenager.',
              ),
              const SizedBox(height: 8),
              AppButton.primary(
                label: 'Confirm outcome for teenager',
                isLoading: _busy,
                onPressed: _busy ? null : () => _confirmOutcome(),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: _busy ? null : () => _confirmOutcome(followUp: true),
                child: const Text('Confirm outcome with follow-up reminder'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
