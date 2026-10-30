import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sibol_app/features/cases/presentation/providers/case_lifecycle_providers.dart';
import 'package:sibol_app/features/coordination/domain/coordination_status.dart';
import 'package:sibol_app/features/coordination/domain/entities/coordination_thread.dart';
import 'package:sibol_app/shared/widgets/app_button.dart';

class MophCoordinationStatusPanel extends ConsumerStatefulWidget {
  const MophCoordinationStatusPanel({
    super.key,
    required this.thread,
  });

  final CoordinationThread thread;

  @override
  ConsumerState<MophCoordinationStatusPanel> createState() =>
      _MophCoordinationStatusPanelState();
}

class _MophCoordinationStatusPanelState
    extends ConsumerState<MophCoordinationStatusPanel> {
  bool _busy = false;

  Future<void> _update(String targetStatus) async {
    if (_busy) return;
    final connectivity = await Connectivity().checkConnectivity();
    if (connectivity.contains(ConnectivityResult.none)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Coordination updates require an online connection.'),
          ),
        );
      }
      return;
    }
    setState(() => _busy = true);
    try {
      await ref.read(caseLifecycleApiProvider).updateMophCoordinationStatus(
            threadId: widget.thread.threadId,
            targetStatus: targetStatus,
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

  List<(String, String)> _allowedActions(CoordinationStatus? current) {
    final c = current ?? CoordinationStatus.submitted;
    switch (c) {
      case CoordinationStatus.submitted:
        return [
          (CoordinationStatus.received.firestoreValue, 'Mark received'),
          (
            CoordinationStatus.additionalInformationRequested.firestoreValue,
            'Request information',
          ),
          (
            CoordinationStatus.unableToAccommodate.firestoreValue,
            'Unable to accommodate',
          ),
        ];
      case CoordinationStatus.received:
        return [
          (
            CoordinationStatus.acceptedForCoordination.firestoreValue,
            'Accept for coordination',
          ),
          (
            CoordinationStatus.additionalInformationRequested.firestoreValue,
            'Request information',
          ),
          (
            CoordinationStatus.unableToAccommodate.firestoreValue,
            'Unable to accommodate',
          ),
        ];
      case CoordinationStatus.acceptedForCoordination:
        return [
          (
            CoordinationStatus.coordinationCompleted.firestoreValue,
            'Mark coordination complete',
          ),
          (
            CoordinationStatus.additionalInformationRequested.firestoreValue,
            'Request information',
          ),
          (
            CoordinationStatus.unableToAccommodate.firestoreValue,
            'Unable to accommodate',
          ),
        ];
      case CoordinationStatus.informationProvided:
        return [
          (CoordinationStatus.received.firestoreValue, 'Mark received'),
          (
            CoordinationStatus.acceptedForCoordination.firestoreValue,
            'Accept for coordination',
          ),
          (
            CoordinationStatus.coordinationCompleted.firestoreValue,
            'Mark coordination complete',
          ),
          (
            CoordinationStatus.unableToAccommodate.firestoreValue,
            'Unable to accommodate',
          ),
        ];
      default:
        return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = widget.thread.coordinationStatus;
    final actions = _allowedActions(status);
    if (actions.isEmpty) {
      return Text(
        'Coordination status: ${status?.label ?? CoordinationStatus.submitted.label}',
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Coordination status: ${status?.label ?? CoordinationStatus.submitted.label}',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: actions
              .map(
                (a) => AppButton.primary(
                  label: a.$2,
                  isLoading: _busy,
                  onPressed: _busy ? null : () => _update(a.$1),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}
