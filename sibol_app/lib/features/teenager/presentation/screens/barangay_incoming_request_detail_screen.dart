import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:sibol_app/core/constants/route_constants.dart';
import 'package:sibol_app/features/coordination/presentation/providers/coordination_providers.dart';
import 'package:sibol_app/features/coordination/presentation/widgets/barangay_moph_referral_action.dart';
import 'package:sibol_app/core/providers/firebase_providers.dart';
import 'package:sibol_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:sibol_app/features/teenager/domain/assistance_request_status.dart';
import 'package:sibol_app/features/org/presentation/providers/org_context_providers.dart';
import 'package:sibol_app/features/org/presentation/widgets/organization_directory_display.dart';
import 'package:sibol_app/features/teenager/presentation/providers/barangay_assistance_providers.dart';
import 'package:sibol_app/features/offline/domain/pending_operation.dart';
import 'package:sibol_app/features/offline/presentation/offline_providers.dart';
import 'package:sibol_app/features/teenager/presentation/widgets/teen_non_emergency_notice.dart';
import 'dart:math';
import 'package:sibol_app/shared/widgets/app_button.dart';
import 'package:sibol_app/shared/widgets/app_error_widget.dart';
import 'package:sibol_app/shared/widgets/app_loading_indicator.dart';
import 'package:sibol_app/shared/widgets/fictional_data_banner.dart';

class BarangayIncomingRequestDetailScreen extends ConsumerStatefulWidget {
  const BarangayIncomingRequestDetailScreen({
    super.key,
    required this.requestId,
  });

  final String requestId;

  @override
  ConsumerState<BarangayIncomingRequestDetailScreen> createState() =>
      _BarangayIncomingRequestDetailScreenState();
}

class _BarangayIncomingRequestDetailScreenState
    extends ConsumerState<BarangayIncomingRequestDetailScreen> {
  bool _acknowledging = false;
  String? _actionError;

  Future<void> _acknowledge() async {
    final uid = ref.read(authStateChangesProvider).value?.uid;
    final orgId = ref.read(barangayAssistanceOrgIdProvider);
    if (uid == null) return;
    if (orgId == null) {
      setState(() => _actionError =
          'Your account is not authorized to acknowledge requests for this organization.');
      return;
    }

    setState(() {
      _actionError = null;
      _acknowledging = true;
    });
    try {
      final sync = ref.read(offlineSyncServiceProvider);
      final operationId =
          'ack-${DateTime.now().microsecondsSinceEpoch}-${Random().nextInt(1 << 31)}';
      final pending = PendingOperation(
        operationId: operationId,
        ownerUid: uid,
        kind: PendingOperationKind.barangayAcknowledge,
        state: PendingOperationState.waitingToSubmit,
        createdAt: DateTime.now(),
        payload: {
          'requestId': widget.requestId,
          'orgId': orgId,
        },
      );
      if (!await sync.hasConnectivity()) {
        await sync.enqueue(pending.copyWith(state: PendingOperationState.savedLocally));
        ref.invalidate(pendingOperationsProvider(uid));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Acknowledgment saved on this device only — not confirmed by the server.',
              ),
            ),
          );
        }
        return;
      }
      await sync.enqueue(pending);
      final outcome = await sync.processOperation(pending);
      ref.invalidate(pendingOperationsProvider(uid));
      if (outcome.state == PendingOperationState.conflict) {
        throw StateError(
          outcome.lastError ??
              'This request was already acknowledged or conflicts with another action.',
        );
      }
      if (outcome.state != PendingOperationState.submittedConfirmed) {
        throw StateError(
          outcome.lastError ??
              'Acknowledgment could not be confirmed. Try again or check your connection.',
        );
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Receipt acknowledged.')),
        );
      }
    } catch (e) {
      setState(() => _actionError = e.toString());
    } finally {
      if (mounted) setState(() => _acknowledging = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final requestAsync =
        ref.watch(barangayAssistanceRequestDetailProvider(widget.requestId));
    final referralExistsAsync =
        ref.watch(assistanceReferralExistsProvider(widget.requestId));
    final dateFmt = DateFormat.yMMMd().add_jm();

    return Scaffold(
      appBar: AppBar(title: const Text('Request details')),
      body: Column(
        children: [
          const FictionalDataBanner(),
          Expanded(
            child: requestAsync.when(
              loading: () => const AppLoadingIndicator(
                message: 'Loading request…',
              ),
              error: (e, _) => AppErrorWidget(message: e.toString()),
              data: (request) {
                if (request == null) {
                  return const Center(
                    child: Text(
                      'This request was not found or is not assigned to your barangay.',
                      textAlign: TextAlign.center,
                    ),
                  );
                }
                final canAcknowledge =
                    request.status == AssistanceRequestStatus.submitted;
                final isAcknowledged =
                    request.status == AssistanceRequestStatus.acknowledged;
                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    const TeenNonEmergencyNotice(),
                    const SizedBox(height: 12),
                    Text(
                      'Acknowledgment records fictional receipt only. It does not '
                      'mean counseling, medical care, or emergency help was provided.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 16),
                    _DetailRow(label: 'Reference', value: request.requestId),
                    _DetailRow(
                      label: 'Category',
                      value: request.category.label,
                    ),
                    _DetailRow(
                      label: 'Submitted',
                      value: dateFmt.format(request.createdAt),
                    ),
                    _DetailRow(
                      label: 'Status',
                      value: request.status.label,
                    ),
                    OrganizationIdentityDetailRows(orgId: request.orgId),
                    if (request.acknowledgedAt != null) ...[
                      _DetailRow(
                        label: 'Acknowledged',
                        value: dateFmt.format(request.acknowledgedAt!),
                      ),
                    ],
                    const SizedBox(height: 16),
                    Text(
                      'Description',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(request.description),
                    if (_actionError != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        _actionError!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ],
                    if (canAcknowledge) ...[
                      const SizedBox(height: 24),
                      AppButton.primary(
                        label: 'Acknowledge receipt',
                        isLoading: _acknowledging,
                        onPressed: _acknowledging ? null : _acknowledge,
                      ),
                    ],
                    BarangayMophReferralAction(
                      isAcknowledged: isAcknowledged,
                      referralExistsAsync: referralExistsAsync,
                      onReferPressed: () => context.push(
                        Routes.barangayCoordinationReferral(widget.requestId),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelLarge,
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
