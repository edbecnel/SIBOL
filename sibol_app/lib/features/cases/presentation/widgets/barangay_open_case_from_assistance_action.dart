import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sibol_app/core/constants/route_constants.dart';
import 'package:sibol_app/features/cases/presentation/providers/case_lifecycle_providers.dart';
import 'package:sibol_app/features/teenager/domain/entities/assistance_request.dart';
import 'package:sibol_app/features/teenager/presentation/providers/barangay_assistance_providers.dart';
import 'package:sibol_app/shared/widgets/app_button.dart';

/// Opens a Barangay case from an acknowledged assistance request (online-only).
class BarangayOpenCaseFromAssistanceAction extends ConsumerStatefulWidget {
  const BarangayOpenCaseFromAssistanceAction({
    super.key,
    required this.request,
  });

  final AssistanceRequest request;

  @override
  ConsumerState<BarangayOpenCaseFromAssistanceAction> createState() =>
      _BarangayOpenCaseFromAssistanceActionState();
}

class _BarangayOpenCaseFromAssistanceActionState
    extends ConsumerState<BarangayOpenCaseFromAssistanceAction> {
  bool _opening = false;
  String? _error;

  String get _idempotencyKey => 'open-assist-${widget.request.requestId}';

  Future<void> _openCase() async {
    if (_opening) return;
    final connectivity = await Connectivity().checkConnectivity();
    if (connectivity.contains(ConnectivityResult.none)) {
      setState(() => _error =
          'Opening a case requires an online connection. Offline follow-ups '
          'and acknowledgment queues are unchanged.');
      return;
    }
    setState(() {
      _opening = true;
      _error = null;
    });
    try {
      final result = await ref.read(caseLifecycleApiProvider).openCaseFromAssistance(
            assistanceRequestId: widget.request.requestId,
            idempotencyKey: _idempotencyKey,
          );
      ref.invalidate(
        barangayAssistanceRequestDetailProvider(widget.request.requestId),
      );
      if (!mounted) return;
      final message = result.idempotent
          ? 'Case already linked to this request.'
          : 'Barangay case opened.';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      context.push(Routes.barangayCaseDetail(result.caseId));
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _opening = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final request = widget.request;
    if (request.hasLinkedCase) {
      final caseId = request.caseId!.trim();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'A Barangay case is already linked to this request.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          AppButton.primary(
            label: 'View linked case',
            onPressed: () => context.push(Routes.barangayCaseDetail(caseId)),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Open a formal Barangay case from this acknowledged request. '
          'This action is online-only and creates one case per request.',
          style: Theme.of(context).textTheme.bodySmall,
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
          label: 'Open Barangay case',
          isLoading: _opening,
          onPressed: _opening ? null : _openCase,
        ),
      ],
    );
  }
}
