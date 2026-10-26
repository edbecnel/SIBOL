import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sibol_app/core/constants/route_constants.dart';
import 'package:sibol_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:sibol_app/features/org/presentation/providers/org_context_providers.dart';
import 'package:sibol_app/features/cases/domain/case_presentation_labels.dart';
import 'package:sibol_app/features/cases/domain/case_status.dart';
import 'package:sibol_app/features/cases/domain/case_validation.dart';
import 'package:sibol_app/features/cases/domain/entities/case_record.dart';
import 'package:sibol_app/core/providers/firebase_providers.dart';
import 'package:sibol_app/features/cases/presentation/providers/case_providers.dart';
import 'package:sibol_app/features/reporting/domain/report_status.dart';
import 'package:sibol_app/shared/widgets/app_button.dart';
import 'package:sibol_app/shared/widgets/app_error_widget.dart';
import 'package:sibol_app/shared/widgets/app_loading_indicator.dart';
import 'package:sibol_app/shared/widgets/app_text_field.dart';
import 'package:sibol_app/shared/widgets/fictional_data_banner.dart';

class CaseEditScreen extends ConsumerStatefulWidget {
  const CaseEditScreen({super.key, this.caseId});

  /// `null` = create mode.
  final String? caseId;

  bool get isCreate => caseId == null;

  @override
  ConsumerState<CaseEditScreen> createState() => _CaseEditScreenState();
}

class _CaseEditScreenState extends ConsumerState<CaseEditScreen> {
  final _demoNameController = TextEditingController();
  final _ageController = TextEditingController();
  final _barangayController = TextEditingController();
  final _notesController = TextEditingController();
  CaseStatus _caseStatus = CaseStatus.active;
  CaseRecord? _existing;
  String? _formError;
  bool _saving = false;
  String? _createCaseDocumentId;

  @override
  void dispose() {
    _demoNameController.dispose();
    _ageController.dispose();
    _barangayController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _populateFromRecord(CaseRecord record) {
    _existing = record;
    _demoNameController.text = record.demoName;
    _ageController.text = '${record.age}';
    _barangayController.text = record.barangay;
    _notesController.text = record.notes;
    _caseStatus = record.caseStatus;
  }

  String? _validateForm({required String? assignedBarangay}) {
    final nameError = CaseValidation.validateDemoName(_demoNameController.text);
    if (nameError != null) return nameError;
    final age = int.tryParse(_ageController.text.trim());
    final ageError = CaseValidation.validateAge(age);
    if (ageError != null) return ageError;
    if (widget.isCreate) {
      if (assignedBarangay == null || assignedBarangay.trim().isEmpty) {
        return 'Organization site label is unavailable. Contact the administrator.';
      }
    } else {
      final barangayError =
          CaseValidation.validateBarangay(_barangayController.text);
      if (barangayError != null) return barangayError;
    }
    final statusError = CaseValidation.validateCaseStatus(_caseStatus);
    if (statusError != null) return statusError;
    return null;
  }

  CaseRecord _buildRecord({required String barangayLabel}) {
    final now = DateTime.now();
    final age = int.parse(_ageController.text.trim());
    if (widget.isCreate) {
      final orgId = ref.read(barangayCaseOrgIdProvider);
      if (orgId == null) {
        throw StateError('Organization context is not available for case create.');
      }
      final caseId = _createCaseDocumentId ??=
          ref.read(caseRepositoryProvider).newCaseDocumentId();
      return CaseRecord(
        caseId: caseId,
        demoName: _demoNameController.text.trim(),
        age: age,
        barangay: barangayLabel.trim(),
        orgId: orgId,
        caseStatus: _caseStatus,
        registeredAt: now,
        notes: _notesController.text.trim(),
        createdAt: now,
        updatedAt: now,
        reportStatus: ReportStatus.notSubmitted,
      );
    }
    final existing = _existing!;
    return CaseRecord(
      caseId: existing.caseId,
      demoName: _demoNameController.text.trim(),
      age: age,
      barangay: _barangayController.text.trim(),
      orgId: existing.orgId,
      caseStatus: _caseStatus,
      registeredAt: existing.registeredAt,
      nextFollowUpAt: existing.nextFollowUpAt,
      notes: _notesController.text.trim(),
      createdAt: existing.createdAt,
      updatedAt: now,
      reportStatus: existing.reportStatus,
    );
  }

  Future<void> _save({required String barangayLabel}) async {
    setState(() => _formError = null);
    final validation = _validateForm(assignedBarangay: barangayLabel);
    if (validation != null) {
      setState(() => _formError = validation);
      return;
    }
    setState(() => _saving = true);
    try {
      final repo = ref.read(caseRepositoryProvider);
      final record = _buildRecord(barangayLabel: barangayLabel);
      if (widget.isCreate) {
        final id = await repo.createCase(record);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                CasePresentationLabels.saveConfirmationSnackbar(
                  hasPendingWritesHint: true,
                ),
              ),
            ),
          );
          context.go(Routes.barangayCaseDetail(id));
        }
      } else {
        await repo.updateCase(record);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                CasePresentationLabels.saveConfirmationSnackbar(
                  hasPendingWritesHint: true,
                ),
              ),
            ),
          );
          context.go(Routes.barangayCaseDetail(record.caseId));
        }
      }
    } catch (e) {
      setState(() => _formError = e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isCreate) {
      final caseAsync = ref.watch(caseEditRecordProvider(widget.caseId!));
      return caseAsync.when(
        loading: () => Scaffold(
          appBar: AppBar(title: const Text('Edit case')),
          body: const AppLoadingIndicator(
            message: 'Loading case from this device…',
          ),
        ),
        error: (e, _) => Scaffold(
          appBar: AppBar(title: const Text('Edit case')),
          body: AppErrorWidget(message: e.toString()),
        ),
        data: (record) {
          if (_existing?.caseId != record.caseId) {
            _populateFromRecord(record);
          }
          return _buildFormScaffold(
            title: 'Edit case',
            headerNote: 'Case ID: ${record.caseId}',
            barangayLabel: record.barangay,
            barangayReadOnly: true,
          );
        },
      );
    }
    final presentationAsync = ref.watch(barangayCaseOrgPresentationProvider);
    return presentationAsync.when(
      loading: () => const Scaffold(
        body: AppLoadingIndicator(message: 'Loading organization…'),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: const Text('New demonstration case')),
        body: AppErrorWidget(message: e.toString()),
      ),
      data: (presentation) => _buildFormScaffold(
        title: 'New demonstration case',
        organizationName: presentation.organizationName,
        caseSiteLabel: presentation.siteLabel,
        barangayReadOnly: true,
      ),
    );
  }

  Widget _buildFormScaffold({
    required String title,
    String? headerNote,
    String? organizationName,
    String? caseSiteLabel,
    String? barangayLabel,
    bool barangayReadOnly = false,
  }) {
    final resolvedSiteLabel = caseSiteLabel ?? barangayLabel ?? '';
    final resolvedOrgName = organizationName ?? barangayLabel ?? '';
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Column(
        children: [
          const FictionalDataBanner(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (headerNote != null) ...[
                  Text(headerNote),
                  const SizedBox(height: 12),
                ],
                AppTextField(
                  controller: _demoNameController,
                  label: 'Demo name',
                ),
                const SizedBox(height: 12),
                AppTextField(
                  controller: _ageController,
                  label: 'Age (13–19)',
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                InputDecorator(
                  decoration: InputDecoration(
                    labelText: widget.isCreate
                        ? 'Barangay organization'
                        : 'Barangay site (on case)',
                  ),
                  child: Text(
                    barangayReadOnly
                        ? resolvedOrgName
                        : _barangayController.text,
                  ),
                ),
                if (widget.isCreate && resolvedSiteLabel.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Case site label: $resolvedSiteLabel',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
                const SizedBox(height: 12),
                DropdownButtonFormField<CaseStatus>(
                  value: _caseStatus,
                  decoration: const InputDecoration(labelText: 'Case status'),
                  items: CaseStatus.values
                      .map(
                        (s) => DropdownMenuItem(
                          value: s,
                          child: Text(
                            CasePresentationLabels.lifecycleStatus(s),
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) setState(() => _caseStatus = value);
                  },
                ),
                const SizedBox(height: 12),
                AppTextField(
                  controller: _notesController,
                  label: 'Notes',
                ),
                if (_formError != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _formError!,
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                  ),
                ],
                const SizedBox(height: 24),
                AppButton.primary(
                  label: widget.isCreate ? 'Create case' : 'Save changes',
                  isLoading: _saving,
                  onPressed: _saving
                      ? null
                      : () => _save(barangayLabel: resolvedSiteLabel),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
