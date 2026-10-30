import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sibol_app/features/cases/presentation/providers/case_lifecycle_providers.dart';
import 'package:sibol_app/features/coordination/domain/coordination_status.dart';
import 'package:sibol_app/features/coordination/domain/entities/coordination_thread.dart';
import 'package:sibol_app/shared/widgets/app_button.dart';

class BarangayCoordinationResponsePanel extends ConsumerStatefulWidget {
  const BarangayCoordinationResponsePanel({
    super.key,
    required this.thread,
  });

  final CoordinationThread thread;

  @override
  ConsumerState<BarangayCoordinationResponsePanel> createState() =>
      _BarangayCoordinationResponsePanelState();
}

class _BarangayCoordinationResponsePanelState
    extends ConsumerState<BarangayCoordinationResponsePanel> {
  bool _busy = false;

  Future<void> _respond() async {
    if (_busy) return;
    final connectivity = await Connectivity().checkConnectivity();
    if (connectivity.contains(ConnectivityResult.none)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Submitting a response requires an online connection.'),
          ),
        );
      }
      return;
    }
    final controller = TextEditingController();
    final summary = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Provide information to hospital'),
        content: TextField(
          controller: controller,
          maxLines: 4,
          decoration: const InputDecoration(
            labelText: 'Administrative response (10–500 characters)',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              final text = controller.text.trim();
              if (text.length < 10) return;
              Navigator.pop(ctx, text);
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
    if (summary == null) return;
    setState(() => _busy = true);
    try {
      await ref.read(caseLifecycleApiProvider).respondToMophInformationRequest(
            threadId: widget.thread.threadId,
            responseSummary: summary,
          );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.thread.coordinationStatus !=
        CoordinationStatus.additionalInformationRequested) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: AppButton.primary(
        label: 'Provide information to hospital',
        isLoading: _busy,
        onPressed: _busy ? null : _respond,
      ),
    );
  }
}
