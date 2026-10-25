import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sibol_app/features/coordination/domain/referral_summary_validation.dart';
import 'package:sibol_app/features/coordination/presentation/providers/coordination_providers.dart';
import 'package:sibol_app/features/teenager/domain/assistance_request_status.dart';
import 'package:sibol_app/features/teenager/presentation/providers/barangay_assistance_providers.dart';
import 'package:sibol_app/shared/widgets/app_button.dart';
import 'package:sibol_app/shared/widgets/app_error_widget.dart';
import 'package:sibol_app/shared/widgets/app_loading_indicator.dart';
import 'package:sibol_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:sibol_app/features/offline/domain/pending_operation.dart';
import 'package:sibol_app/features/offline/presentation/offline_providers.dart';
import 'package:sibol_app/features/org/presentation/widgets/organization_directory_display.dart';
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
  final _summaryController = TextEditingController();
  bool _showPreview = false;
  bool _submitting = false;
  String? _error;
  String? _fieldError;

  @override
  void dispose() {
    _summaryController.dispose();
    super.dispose();
  }

  String? _validateSummary() {
    return ReferralSummaryValidation.validate(_summaryController.text);
  }

  void _goToPreview() {
    final err = _validateSummary();
    setState(() {
      _fieldError = err;
      _error = null;
      if (err == null) _showPreview = true;
    });
  }

  Future<void> _submit() async {
    if (_submitting) return;
    final summary = _summaryController.text.trim();
    final err = ReferralSummaryValidation.validate(summary);
    if (err != null) {
      setState(() => _fieldError = err);
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final uid = ref.read(authStateChangesProvider).value?.uid;
      if (uid == null) return;
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
          'summary': summary,
        },
      );
      if (!await sync.hasConnectivity()) {
        await sync.enqueue(pending.copyWith(state: PendingOperationState.savedLocally));
        ref.invalidate(pendingOperationsProvider(uid));
        if (!mounted) return;
        await showDialog<void>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Referral saved locally'),
            content: const Text(
              'Your referral is stored on this device only. MOPH has not '
              'received it until the server confirms submission.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
        if (mounted) context.pop();
        return;
      }
      await sync.enqueue(pending);
      await sync.syncForUser(uid);
      ref.invalidate(pendingOperationsProvider(uid));
      final stored = await ref.read(pendingOperationStoreProvider).loadForUser(uid);
      final done = stored.firstWhere((o) => o.operationId == operationId);
      if (done.state == PendingOperationState.conflict) {
        setState(() => _error = done.lastError);
        return;
      }
      if (done.state != PendingOperationState.submittedConfirmed) {
        setState(() => _error = done.lastError ?? 'Referral not confirmed by server.');
        return;
      }
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Referral submitted'),
          content: const Text(
            'MOPH can review this referral in their coordination inbox. '
            'This is fictional demonstration data.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      if (mounted) context.pop();
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final requestAsync = ref.watch(
      barangayAssistanceRequestDetailProvider(widget.assistanceRequestId),
    );
    final referralExistsAsync = ref.watch(
      assistanceReferralExistsProvider(widget.assistanceRequestId),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('MOPH coordination referral'),
      ),
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
                  return const Center(child: Text('Request not found.'));
                }
                if (request.status != AssistanceRequestStatus.acknowledged) {
                  return const Center(
                    child: Text(
                      'Only acknowledged requests can be referred to MOPH.',
                      textAlign: TextAlign.center,
                    ),
                  );
                }
                return referralExistsAsync.when(
                  loading: () => const AppLoadingIndicator(),
                  error: (e, _) => AppErrorWidget(message: e.toString()),
                  data: (exists) {
                    if (exists) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: Text(
                            'A coordination referral already exists for this '
                            'assistance request.',
                            textAlign: TextAlign.center,
                          ),
                        ),
                      );
                    }
                    if (_showPreview) {
                      return _PreviewStep(
                        categoryLabel: request.category.label,
                        orgId: request.orgId,
                        historicalSiteLabel: request.barangay,
                        summary: _summaryController.text.trim(),
                        submitting: _submitting,
                        error: _error,
                        onBack: () => setState(() => _showPreview = false),
                        onSubmit: _submit,
                      );
                    }
                    return ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        Text(
                          'Minimum-information referral (DEC-CASE-001)',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Prepare a summary for MOPH. Do not include the teen\'s '
                          'name, contact details, or other identifying information. '
                          'The original teen request text is not sent to MOPH.',
                        ),
                        const SizedBox(height: 16),
                        Text('Category: ${request.category.label}'),
                        OrganizationIdentityDetailRows(
                          orgId: request.orgId,
                          historicalSiteLabel: request.barangay,
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _summaryController,
                          maxLines: 8,
                          maxLength: ReferralSummaryValidation.maxLength,
                          decoration: InputDecoration(
                            labelText: 'Barangay-prepared summary for MOPH',
                            errorText: _fieldError,
                            border: const OutlineInputBorder(),
                          ),
                          onChanged: (_) {
                            if (_fieldError != null) {
                              setState(() => _fieldError = _validateSummary());
                            }
                          },
                        ),
                        if (_error != null) ...[
                          const SizedBox(height: 12),
                          Text(
                            _error!,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        ],
                        const SizedBox(height: 24),
                        AppButton.primary(
                          label: 'Review before submit',
                          onPressed: _goToPreview,
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _PreviewStep extends ConsumerWidget {
  const _PreviewStep({
    required this.categoryLabel,
    required this.orgId,
    required this.historicalSiteLabel,
    required this.summary,
    required this.submitting,
    required this.error,
    required this.onBack,
    required this.onSubmit,
  });

  final String categoryLabel;
  final String orgId;
  final String historicalSiteLabel;
  final String summary;
  final bool submitting;
  final String? error;
  final VoidCallback onBack;
  final Future<void> Function() onSubmit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Confirm MOPH-visible content',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        const Text(
          'Only the fields below will be visible to MOPH. Verify that your '
          'summary does not identify the teen.',
        ),
        const SizedBox(height: 16),
        _PreviewRow(label: 'Category', value: categoryLabel),
        OrganizationIdentityDetailRows(
          orgId: orgId,
          historicalSiteLabel: historicalSiteLabel,
        ),
        _PreviewRow(label: 'Summary', value: summary),
        if (error != null) ...[
          const SizedBox(height: 12),
          Text(
            error!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ],
        const SizedBox(height: 24),
        AppButton.primary(
          label: 'Submit referral to MOPH',
          isLoading: submitting,
          onPressed: submitting ? null : onSubmit,
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: submitting ? null : onBack,
          child: const Text('Edit summary'),
        ),
      ],
    );
  }
}

class _PreviewRow extends StatelessWidget {
  const _PreviewRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 4),
          Text(value),
        ],
      ),
    );
  }
}
