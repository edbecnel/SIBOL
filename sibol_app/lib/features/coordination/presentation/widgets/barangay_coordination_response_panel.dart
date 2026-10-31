import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sibol_app/features/cases/presentation/providers/case_lifecycle_providers.dart';
import 'package:sibol_app/features/coordination/domain/coordination_status.dart';
import 'package:sibol_app/features/coordination/domain/entities/coordination_thread.dart';
import 'package:sibol_app/features/disclosure/domain/disclosure_constants.dart';
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
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Structured response to hospital'),
        content: const Text(
          'Submit an administrative template response without free text.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Submit update'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() => _busy = true);
    try {
      await ref.read(caseLifecycleApiProvider).respondToMophInformationRequest(
            threadId: widget.thread.threadId,
            responseTemplateCode: ResponseTemplateCodes.administrativeUpdate,
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
        label: 'Provide structured information to hospital',
        isLoading: _busy,
        onPressed: _busy ? null : _respond,
      ),
    );
  }
}
