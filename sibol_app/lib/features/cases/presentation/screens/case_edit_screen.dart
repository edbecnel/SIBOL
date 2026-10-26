import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sibol_app/core/constants/route_constants.dart';
import 'package:sibol_app/core/providers/firebase_providers.dart';
import 'package:sibol_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:sibol_app/features/cases/data/case_registration_api.dart';
import 'package:sibol_app/features/cases/domain/case_completeness.dart';
import 'package:sibol_app/features/cases/domain/case_presentation_labels.dart';
import 'package:sibol_app/features/cases/domain/case_status.dart';
import 'package:sibol_app/features/cases/domain/case_subject_kind.dart';
import 'package:sibol_app/features/cases/domain/case_validation.dart';
import 'package:sibol_app/features/cases/domain/entities/case_record.dart';
import 'package:sibol_app/features/cases/domain/entities/case_record_extensions.dart';
import 'package:sibol_app/features/cases/presentation/providers/case_providers.dart';
import 'package:sibol_app/features/org/presentation/providers/org_context_providers.dart';
import 'package:sibol_app/features/reporting/domain/report_status.dart';
import 'package:sibol_app/shared/widgets/app_button.dart';
import 'package:sibol_app/shared/widgets/app_error_widget.dart';
import 'package:sibol_app/shared/widgets/app_loading_indicator.dart';
import 'package:sibol_app/shared/widgets/app_text_field.dart';
import 'package:sibol_app/shared/widgets/fictional_data_banner.dart';

class CaseEditScreen extends ConsumerStatefulWidget {
  const CaseEditScreen({super.key, this.caseId});

  final String? caseId;

  bool get isCreate => caseId == null;

  @override
  ConsumerState<CaseEditScreen> createState() => _CaseEditScreenState();
}

class _CaseEditScreenState extends ConsumerState<CaseEditScreen> {
  final _fullNameController = TextEditingController();
  final _dobController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _parentContactController = TextEditingController();
  final _notesController = TextEditingController();
  final _legacyAgeController = TextEditingController();

  CaseSubjectKind _subjectKind = CaseSubjectKind.unregistered;
  CaseStatus _caseStatus = CaseStatus.active;
  CaseRecord? _existing;
  String? _formError;
  bool _saving = false;
  String? _createCaseDocumentId;
  RegisteredTeenListEntry? _selectedTeen;
  ResolvedRegisteredTeenForCase? _resolvedTeen;
  List<RegisteredTeenListEntry> _teenOptions = [];
  bool _loadingTeens = false;
  bool _teenOptionsRequested = false;

  @override
  void dispose() {
    _fullNameController.dispose();
    _dobController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _parentContactController.dispose();
    _notesController.dispose();
    _legacyAgeController.dispose();
    super.dispose();
  }

  void _populateFromRecord(CaseRecord record) {
    _existing = record;
    _fullNameController.text = record.displayFullName;
    _dobController.text = record.dateOfBirth ?? '';
    _emailController.text = record.contactEmail ?? '';
    _phoneController.text = record.contactPhone ?? '';
    _parentContactController.text = record.parentGuardianContact ?? '';
    _notesController.text = record.notes;
    _legacyAgeController.text = '${record.age}';
    _caseStatus = record.caseStatus;
    _subjectKind = record.resolvedSubjectKind;
    if (record.teenUid != null && record.teenUid!.isNotEmpty) {
      _selectedTeen = RegisteredTeenListEntry(
        teenUid: record.teenUid!,
        displayName: record.displayFullName,
      );
    }
  }

  bool get _isLegacyDocument =>
      _existing != null &&
      _existing!.caseCompleteness == null &&
      _existing!.subjectKind == null;

  Future<void> _loadTeenOptions(String orgId) async {
    setState(() => _loadingTeens = true);
    try {
      final api = ref.read(caseRegistrationApiProvider);
      final teens = await api.listRegisteredTeens(orgId: orgId);
      if (mounted) setState(() => _teenOptions = teens);
    } catch (_) {
      if (mounted) {
        setState(() => _teenOptions = []);
      }
    } finally {
      if (mounted) setState(() => _loadingTeens = false);
    }
  }

  Future<bool> _isOnline() async {
    final result = await Connectivity().checkConnectivity();
    return !result.contains(ConnectivityResult.none);
  }

  Future<void> _resolveSelectedTeen(String orgId) async {
    final teen = _selectedTeen;
    if (teen == null) return;
    if (!await _isOnline()) {
      setState(() {
        _formError =
            'Registered teen verification requires an internet connection.';
      });
      return;
    }
    setState(() => _formError = null);
    try {
      final resolved = await ref.read(caseRegistrationApiProvider).resolveRegisteredTeen(
            orgId: orgId,
            teenUid: teen.teenUid,
          );
      setState(() {
        _resolvedTeen = resolved;
        _fullNameController.text = resolved.fullName;
        if (resolved.dateOfBirth != null) {
          _dobController.text = resolved.dateOfBirth!;
        }
        if (resolved.barangay != null && resolved.barangay!.isNotEmpty) {
          // barangay comes from org site on create
        }
        _emailController.text = resolved.contactEmail ?? '';
        _phoneController.text = resolved.contactPhone ?? '';
        _parentContactController.text = resolved.parentGuardianContact ?? '';
      });
    } catch (e) {
      setState(() => _formError = e.toString());
    }
  }

  CaseRecord _buildRecord({
    required String barangayLabel,
    required String orgId,
    required CaseCompleteness completeness,
  }) {
    final now = DateTime.now();
    final existing = _existing;
    final caseId = widget.isCreate
        ? (_createCaseDocumentId ??=
            ref.read(caseRepositoryProvider).newCaseDocumentId())
        : existing!.caseId;

    final useExtended = widget.isCreate ||
        (!_isLegacyDocument || completeness != CaseCompleteness.legacyIncomplete);

    final dob = _dobController.text.trim();
    final resolved = _resolvedTeen;
    return CaseRecord(
      caseId: caseId,
      demoName: _fullNameController.text.trim(),
      fullName: _fullNameController.text.trim(),
      age: int.tryParse(_legacyAgeController.text.trim()) ?? 0,
      barangay: barangayLabel.trim(),
      orgId: orgId,
      caseStatus: _caseStatus,
      registeredAt: existing?.registeredAt ?? now,
      notes: _notesController.text.trim(),
      createdAt: existing?.createdAt ?? now,
      updatedAt: now,
      reportStatus: existing?.reportStatus ?? ReportStatus.notSubmitted,
      subjectKind: useExtended ? _subjectKind : null,
      caseCompleteness: useExtended ? completeness : null,
      dateOfBirth: dob.isEmpty ? null : dob,
      contactEmail: _emailController.text.trim().isEmpty
          ? null
          : _emailController.text.trim(),
      contactPhone: _phoneController.text.trim().isEmpty
          ? null
          : _phoneController.text.trim(),
      parentGuardianContact: _parentContactController.text.trim().isEmpty
          ? null
          : _parentContactController.text.trim(),
      teenUid: _subjectKind == CaseSubjectKind.registered
          ? resolved?.teenUid ?? _selectedTeen?.teenUid ?? existing?.teenUid
          : null,
      linkedAccountEmail: _subjectKind == CaseSubjectKind.registered
          ? resolved?.linkedAccountEmail ?? existing?.linkedAccountEmail
          : null,
      identityLinkedAt: _subjectKind == CaseSubjectKind.registered
          ? (resolved != null ? DateTime.now().toUtc() : existing?.identityLinkedAt)
          : null,
    );
  }

  String? _validate(CaseRecord record, CaseCompleteness completeness) {
    if (_subjectKind == CaseSubjectKind.registered &&
        completeness == CaseCompleteness.active &&
        _resolvedTeen == null &&
        (record.teenUid == null || record.linkedAccountEmail == null)) {
      return 'Verify the registered teen account while online before activating.';
    }
    return CaseValidation.validateForWrite(
      record.copyWith(caseCompleteness: completeness),
    );
  }

  Future<void> _saveDraft({required String barangayLabel, required String orgId}) async {
    final record = _buildRecord(
      barangayLabel: barangayLabel,
      orgId: orgId,
      completeness: CaseCompleteness.draft,
    );
    final error = _validate(record, CaseCompleteness.draft);
    if (error != null) {
      setState(() => _formError = error);
      return;
    }
    await _persist(record);
  }

  Future<void> _saveActive({required String barangayLabel, required String orgId}) async {
    final completeness = _isLegacyDocument &&
            _dobController.text.trim().isEmpty &&
            !_subjectKindIsRegisteredWithResolvedProfile()
        ? CaseCompleteness.legacyIncomplete
        : CaseCompleteness.active;
    final record = _buildRecord(
      barangayLabel: barangayLabel,
      orgId: orgId,
      completeness: completeness,
    );
    final error = _validate(record, completeness);
    if (error != null) {
      setState(() => _formError = error);
      return;
    }
    await _persist(record);
  }

  bool _subjectKindIsRegisteredWithResolvedProfile() =>
      _subjectKind == CaseSubjectKind.registered && _resolvedTeen != null;

  Future<void> _persist(CaseRecord record) async {
    setState(() {
      _formError = null;
      _saving = true;
    });
    try {
      final repo = ref.read(caseRepositoryProvider);
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
        appBar: AppBar(title: const Text('New case')),
        body: AppErrorWidget(message: e.toString()),
      ),
      data: (presentation) {
        final orgId = ref.watch(barangayCaseOrgIdProvider);
        if (orgId != null && !_teenOptionsRequested) {
          _teenOptionsRequested = true;
          _loadTeenOptions(orgId);
        }
        return _buildFormScaffold(
          title: 'New case',
          organizationName: presentation.organizationName,
          caseSiteLabel: presentation.siteLabel,
          barangayLabel: presentation.siteLabel,
          orgId: orgId,
        );
      },
    );
  }

  Widget _buildFormScaffold({
    required String title,
    String? headerNote,
    String? organizationName,
    String? caseSiteLabel,
    required String barangayLabel,
    String? orgId,
  }) {
    final resolvedOrgId = orgId ?? _existing?.orgId ?? ref.read(barangayCaseOrgIdProvider);
    final showLegacyAge = _isLegacyDocument && _dobController.text.trim().isEmpty;
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
                if (organizationName != null) ...[
                  Text('Organization: $organizationName'),
                  if (caseSiteLabel != null)
                    Text('Case site label: $caseSiteLabel'),
                  const SizedBox(height: 12),
                ],
                if (!widget.isCreate && _existing != null)
                  Text(_existing!.completeness == CaseCompleteness.draft
                      ? 'This case is saved as a draft.'
                      : _existing!.completeness == CaseCompleteness.legacyIncomplete
                          ? 'Legacy record — add date of birth and contact when ready.'
                          : 'Active case record.'),
                const SizedBox(height: 12),
                SegmentedButton<CaseSubjectKind>(
                  segments: const [
                    ButtonSegment(
                      value: CaseSubjectKind.unregistered,
                      label: Text('No SIBOL account'),
                    ),
                    ButtonSegment(
                      value: CaseSubjectKind.registered,
                      label: Text('Registered teen'),
                    ),
                  ],
                  selected: {_subjectKind},
                  onSelectionChanged: widget.isCreate || _existing?.teenUid == null
                      ? (selection) {
                          setState(() {
                            _subjectKind = selection.first;
                            _resolvedTeen = null;
                          });
                        }
                      : null,
                ),
                if (_subjectKind == CaseSubjectKind.registered) ...[
                  const SizedBox(height: 12),
                  if (_loadingTeens)
                    const LinearProgressIndicator()
                  else if (resolvedOrgId != null)
                    DropdownMenu<RegisteredTeenListEntry>(
                      label: const Text('Registered teen account'),
                      dropdownMenuEntries: _teenOptions
                          .map(
                            (t) => DropdownMenuEntry(
                              value: t,
                              label: t.displayName,
                            ),
                          )
                          .toList(),
                      onSelected: (teen) async {
                        setState(() => _selectedTeen = teen);
                        if (teen != null && resolvedOrgId != null) {
                          await _resolveSelectedTeen(resolvedOrgId);
                        }
                      },
                    ),
                  if (_resolvedTeen?.linkedAccountEmail != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        'Account email: ${_resolvedTeen!.linkedAccountEmail}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                ],
                const SizedBox(height: 12),
                AppTextField(
                  controller: _fullNameController,
                  label: 'Full name',
                  enabled: !(_subjectKind == CaseSubjectKind.registered &&
                      _resolvedTeen != null),
                ),
                const SizedBox(height: 12),
                AppTextField(
                  controller: _dobController,
                  label: 'Date of birth (YYYY-MM-DD)',
                  enabled: !(_subjectKind == CaseSubjectKind.registered &&
                      _resolvedTeen?.dateOfBirth != null),
                ),
                if (showLegacyAge) ...[
                  const SizedBox(height: 12),
                  AppTextField(
                    controller: _legacyAgeController,
                    label: 'Age (legacy record)',
                    keyboardType: TextInputType.number,
                  ),
                ],
                const SizedBox(height: 12),
                AppTextField(
                  controller: _emailController,
                  label: 'Contact email (optional)',
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 12),
                AppTextField(
                  controller: _phoneController,
                  label: 'Contact phone (optional)',
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 8),
                Text(
                  'At least one contact method (email or phone) is required to activate a case.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 12),
                AppTextField(
                  controller: _parentContactController,
                  label: 'Parent/guardian contact (optional)',
                ),
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
                  label: 'Case notes (optional)',
                  maxLines: 3,
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
                  label: widget.isCreate ? 'Save draft' : 'Save as draft',
                  isLoading: _saving,
                  onPressed: _saving || resolvedOrgId == null
                      ? null
                      : () => _saveDraft(
                            barangayLabel: barangayLabel,
                            orgId: resolvedOrgId!,
                          ),
                ),
                const SizedBox(height: 8),
                AppButton.primary(
                  label: widget.isCreate ? 'Create active case' : 'Save active case',
                  isLoading: _saving,
                  onPressed: _saving || resolvedOrgId == null
                      ? null
                      : () => _saveActive(
                            barangayLabel: barangayLabel,
                            orgId: resolvedOrgId!,
                          ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
