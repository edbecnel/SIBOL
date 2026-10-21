import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sibol_app/core/constants/route_constants.dart';
import 'package:sibol_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:sibol_app/features/teenager/domain/assistance_request_category.dart';
import 'package:sibol_app/features/teenager/domain/assistance_request_validation.dart';
import 'package:sibol_app/core/providers/firebase_providers.dart';
import 'package:sibol_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:sibol_app/features/teenager/presentation/widgets/teen_non_emergency_notice.dart';
import 'package:sibol_app/shared/widgets/app_button.dart';
import 'package:sibol_app/shared/widgets/app_text_field.dart';
import 'package:sibol_app/shared/widgets/fictional_data_banner.dart';

class AssistanceRequestFormScreen extends ConsumerStatefulWidget {
  const AssistanceRequestFormScreen({super.key});

  @override
  ConsumerState<AssistanceRequestFormScreen> createState() =>
      _AssistanceRequestFormScreenState();
}

class _AssistanceRequestFormScreenState
    extends ConsumerState<AssistanceRequestFormScreen> {
  final _descriptionController = TextEditingController();
  AssistanceRequestCategory? _category;
  String? _formError;
  bool _submitting = false;

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _formError = null);
    final categoryError =
        AssistanceRequestValidation.validateCategory(_category);
    final descriptionError = AssistanceRequestValidation.validateDescription(
      _descriptionController.text,
    );
    final error = categoryError ?? descriptionError;
    if (error != null) {
      setState(() => _formError = error);
      return;
    }

    final uid = ref.read(authStateChangesProvider).value?.uid;
    final barangay = ref.read(userProfileProvider).value?.assignedBarangay;
    if (uid == null) {
      setState(() => _formError = 'You must be signed in to submit a request.');
      return;
    }
    if (barangay == null || barangay.isEmpty) {
      setState(() => _formError =
          'Your demo profile is missing barangay assignment. Contact the administrator.');
      return;
    }

    setState(() => _submitting = true);
    try {
      final id = await ref
          .read(assistanceRequestRepositoryProvider)
          .createRequest(
            teenUid: uid,
            barangay: barangay,
            category: _category!,
            description: _descriptionController.text,
          );
      if (mounted) {
        context.go(Routes.teenAssistanceDetail(id));
      }
    } catch (e) {
      setState(() => _formError = e.toString());
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New support request')),
      body: Column(
        children: [
          const FictionalDataBanner(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const TeenNonEmergencyNotice(),
                const SizedBox(height: 16),
                DropdownButtonFormField<AssistanceRequestCategory>(
                  value: _category,
                  decoration: const InputDecoration(
                    labelText: 'Request category',
                  ),
                  items: AssistanceRequestCategory.values
                      .map(
                        (c) => DropdownMenuItem(
                          value: c,
                          child: Text(c.label),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => setState(() => _category = value),
                ),
                const SizedBox(height: 12),
                AppTextField(
                  controller: _descriptionController,
                  label: 'Description (fictional demo content)',
                  keyboardType: TextInputType.multiline,
                  maxLines: 5,
                  minLines: 3,
                ),
                const SizedBox(height: 8),
                Text(
                  'Use fictional demonstration text only (min '
                  '${AssistanceRequestValidation.minDescriptionLength} characters).',
                  style: Theme.of(context).textTheme.bodySmall,
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
                  label: 'Submit request',
                  isLoading: _submitting,
                  onPressed: _submitting ? null : _submit,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
