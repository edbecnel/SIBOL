import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sibol_app/features/coordination/domain/repositories/coordination_repository.dart';
import 'package:sibol_app/features/coordination/presentation/providers/coordination_providers.dart';
import 'package:sibol_app/features/disclosure/domain/disclosure_constants.dart';
import 'package:sibol_app/features/disclosure/presentation/providers/disclosure_providers.dart';
import 'package:sibol_app/features/teenager/domain/assistance_request_status.dart';
import 'package:sibol_app/features/teenager/presentation/providers/barangay_assistance_providers.dart';
import 'package:sibol_app/shared/widgets/app_button.dart';
import 'package:sibol_app/shared/widgets/app_error_widget.dart';
import 'package:sibol_app/shared/widgets/app_loading_indicator.dart';
import 'package:sibol_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:sibol_app/features/offline/domain/pending_operation.dart';
import 'package:sibol_app/features/offline/presentation/offline_providers.dart';
import 'package:sibol_app/shared/widgets/fictional_data_banner.dart';
import 'dart:math';

class BarangayCoordinationReferralScreen extends ConsumerStatefulWidget {
  const BarangayCoordinationReferralScreen({
    super.key,
    required this.assistanceRequestId,
  });

  final String assistanceRequestId;

  @override
  ConsumerState<BarangayCoordinationReferralScreen> createState() =>
      _BarangayCoordinationReferralScreenState();
}

class _BarangayCoordinationReferralScreenState
    extends ConsumerState<BarangayCoordinationReferralScreen> {
  String _purposeCode = ReferralPurposeCodes.hospitalCoordination;
  final _needCodes = {CoordinationNeedCodes.scheduleCoordination};
  String _disclosureMode = 'minimum';
  String? _authorizationId;
  bool _submitting = false;
  String? _error;

  Future<void> _submit() async {
    if (_submitting) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final uid = ref.read(authStateChangesProvider).value?.uid;
      if (uid == null) return;
      final input = StructuredCoordinationReferralInput(
        assistanceRequestId: widget.assistanceRequestId,
        disclosureMode: _disclosureMode,
        referralPurposeCode: _purposeCode,
        coordinationNeedCodes: _needCodes.toList(),
        authorizationId:
            _disclosureMode == 'authorized' ? _authorizationId : null,
      );
      final sync = ref.read(offlineSyncServiceProvider);
      final operationId =
          'ref-${DateTime.now().microsecondsSinceEpoch}-${Random().nextInt(1 << 31)}';
      final pending = PendingOperation(
        operationId: operationId,
        ownerUid: uid,
        kind: PendingOperationKind.barangayReferral,
        state: PendingOperationState.waitingToSubmit,
        createdAt: DateTime.now(),
        payload: {
          'assistanceRequestId': widget.assistanceRequestId,
          'disclosureMode': _disclosureMode,
          'referralPurposeCode': _purposeCode,
          'coordinationNeedCodes': _needCodes.join(','),
          if (_authorizationId != null) 'authorizationId': _authorizationId!,
        },
      );
      if (!await sync.hasConnectivity()) {
        await sync.enqueue(pending.copyWith(state: PendingOperationState.savedLocally));
        ref.invalidate(pendingOperationsProvider(uid));
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Referral queued locally. Server will re-validate authorization on sync.',
            ),
          ),
        );
        context.pop();
        return;
      }
      await ref.read(coordinationRepositoryProvider).createCoordinationReferral(input);
      ref.invalidate(assistanceReferralExistsProvider(widget.assistanceRequestId));
      if (!mounted) return;
      context.pop();
    } catch (e) {
      setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final requestAsync =
        ref.watch(barangayAssistanceRequestDetailProvider(widget.assistanceRequestId));
    final auths = ref.watch(
      disclosureAuthorizationsForAssistanceProvider(widget.assistanceRequestId),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Structured MOPH referral')),
      body: Column(
        children: [
          const FictionalDataBanner(),
          Expanded(
            child: requestAsync.when(
              loading: () => const AppLoadingIndicator(message: 'Loading…'),
              error: (e, _) => AppErrorWidget(message: e.toString()),
              data: (request) {
                if (request == null) {
                  return const Center(child: Text('Request not found.'));
                }
                if (request.status != AssistanceRequestStatus.acknowledged) {
                  return const Center(
                    child: Text('Acknowledge the request before referral.'),
                  );
                }
                final approvedAuth = auths.maybeWhen(
                  data: (items) => items.where((a) => a.status == 'approved').toList(),
                  orElse: () => <DisclosureAuthorizationView>[],
                );
                if (_authorizationId == null && approvedAuth.isNotEmpty) {
                  _authorizationId = approvedAuth.last.authorizationId;
                }
                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    const Text(
                      'Minimum-information referrals use purpose and need codes only '
                      '(no free-text summary). Authorized mode requires approved '
                      'teen authorization and legal activation.',
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _purposeCode,
                      decoration: const InputDecoration(labelText: 'Purpose'),
                      items: const [
                        DropdownMenuItem(
                          value: ReferralPurposeCodes.hospitalCoordination,
                          child: Text('Hospital coordination'),
                        ),
                        DropdownMenuItem(
                          value: ReferralPurposeCodes.followUpSupport,
                          child: Text('Follow-up support'),
                        ),
                      ],
                      onChanged: (v) => setState(() => _purposeCode = v!),
                    ),
                    CheckboxListTile(
                      value: _needCodes.contains(CoordinationNeedCodes.scheduleCoordination),
                      onChanged: (v) => setState(() {
                        if (v == true) {
                          _needCodes.add(CoordinationNeedCodes.scheduleCoordination);
                        } else {
                          _needCodes.remove(CoordinationNeedCodes.scheduleCoordination);
                        }
                      }),
                      title: const Text('Schedule coordination'),
                    ),
                    const SizedBox(height: 8),
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(value: 'minimum', label: Text('Minimum')),
                        ButtonSegment(value: 'authorized', label: Text('Authorized')),
                      ],
                      selected: {_disclosureMode},
                      onSelectionChanged: (s) =>
                          setState(() => _disclosureMode = s.first),
                    ),
                    if (_disclosureMode == 'authorized') ...[
                      if (!DisclosureLegalPolicy.identifyingDisclosureActivated)
                        const Text(
                          'Legal gate: identifying disclosure disabled on this build.',
                        ),
                      if (approvedAuth.isEmpty)
                        const Text('No approved authorization on file.'),
                    ],
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                    ],
                    const SizedBox(height: 24),
                    AppButton.primary(
                      label: 'Submit referral',
                      isLoading: _submitting,
                      onPressed: _submitting ? null : _submit,
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
