import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sibol_app/core/constants/route_constants.dart';
import 'package:sibol_app/core/errors/user_error_message.dart';
import 'package:sibol_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:sibol_app/features/auth/presentation/sign_out_pending_guard.dart';
import 'package:sibol_app/features/cases/domain/case_date_of_birth.dart';
import 'package:sibol_app/features/geo/presentation/geo_providers.dart';
import 'package:sibol_app/features/geo/presentation/psgc_geo_picker.dart';
import 'package:sibol_app/features/teen_registration/domain/teen_onboarding_policy.dart';
import 'package:sibol_app/features/teen_registration/domain/teen_registration_validation.dart';
import 'package:sibol_app/features/teen_registration/presentation/providers/teen_registration_intent_providers.dart';
import 'package:sibol_app/features/teen_registration/presentation/providers/teen_registration_providers.dart';
import 'package:sibol_app/shared/widgets/app_button.dart';
import 'package:sibol_app/shared/widgets/app_text_field.dart';
import 'package:sibol_app/shared/widgets/fictional_data_banner.dart';

class TeenRegistrationScreen extends ConsumerStatefulWidget {
  const TeenRegistrationScreen({super.key});

  @override
  ConsumerState<TeenRegistrationScreen> createState() =>
      _TeenRegistrationScreenState();
}

class _TeenRegistrationScreenState extends ConsumerState<TeenRegistrationScreen> {
  int _step = 0;
  final _signInEmailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _dobController = TextEditingController();
  final _contactEmailController = TextEditingController();
  final _contactPhoneController = TextEditingController();
  PsgcSelection? _psgcSelection;
  bool _consent = false;
  bool _submitting = false;
  String? _error;
  bool _contactEmailManuallyEdited = false;

  @override
  void initState() {
    super.initState();
    _signInEmailController.addListener(_maybePrefillContactEmail);
    _contactEmailController.addListener(_onContactEmailEdited);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(teenRegistrationIntentProvider.notifier).markInProgress();
    });
  }

  void _maybePrefillContactEmail() {
    if (_contactEmailManuallyEdited) return;
    final signIn = _signInEmailController.text.trim();
    if (_contactEmailController.text.trim() != signIn) {
      _contactEmailController.text = signIn;
    }
  }

  void _onContactEmailEdited() {
    final signIn = _signInEmailController.text.trim();
    final contact = _contactEmailController.text.trim();
    if (contact.isNotEmpty && contact != signIn) {
      _contactEmailManuallyEdited = true;
    }
  }

  @override
  void dispose() {
    _signInEmailController.removeListener(_maybePrefillContactEmail);
    _contactEmailController.removeListener(_onContactEmailEdited);
    _signInEmailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _fullNameController.dispose();
    _dobController.dispose();
    _contactEmailController.dispose();
    _contactPhoneController.dispose();
    super.dispose();
  }

  String? _computedAgeLabel() {
    final age = TeenRegistrationValidation.computedAge(_dobController.text);
    if (age == null) return null;
    return 'Calculated age: $age';
  }

  Future<void> _submitRegistration() async {
    final authUser = ref.read(authStateChangesProvider).value;
    final needsAuth = authUser == null;

    final validation = needsAuth
        ? TeenRegistrationValidation.validateBeforeAccountCreation(
            fullName: _fullNameController.text,
            dateOfBirth: _dobController.text,
            contactEmail: _contactEmailController.text,
            contactPhone: _contactPhoneController.text,
            barangaySelected: _psgcSelection != null,
            signInEmail: _signInEmailController.text,
            password: _passwordController.text,
            confirmPassword: _confirmPasswordController.text,
            privacyConsent: _consent,
          )
        : TeenRegistrationValidation.validateBeforeProfileCompletion(
            fullName: _fullNameController.text,
            dateOfBirth: _dobController.text,
            contactEmail: _contactEmailController.text,
            contactPhone: _contactPhoneController.text,
            barangaySelected: _psgcSelection != null,
            privacyConsent: _consent,
          );

    if (validation != null) {
      setState(() => _error = validation);
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      if (needsAuth) {
        await ref.read(authControllerProvider.notifier).registerWithEmail(
              _signInEmailController.text.trim(),
              _passwordController.text,
            );
      }

      final sel = _psgcSelection!;
      await ref.read(teenRegistrationApiProvider).registerTeenAccount(
            selectedBarangayPsgcCode: sel.psgcBarangayCode,
            psgcVersion: sel.psgcVersion,
            psgcRegionCode: sel.psgcRegionCode,
            psgcProvinceCode: sel.psgcProvinceCode,
            psgcCityMunCode: sel.psgcCityMunCode,
            displayName: _fullNameController.text.trim(),
            dateOfBirth: CaseDateOfBirth.parse(_dobController.text.trim())!
                .toStorageString(),
            contactEmail: _contactEmailController.text.trim().isEmpty
                ? null
                : _contactEmailController.text.trim(),
            contactPhone: _contactPhoneController.text.trim().isEmpty
                ? null
                : _contactPhoneController.text.trim(),
            privacyConsentAcknowledged: true,
          );

      await ref.read(teenRegistrationIntentProvider.notifier).clear();
      if (TeenOnboardingPolicy.requireEmailVerificationBeforeAssistance) {
        await ref.read(authControllerProvider.notifier).sendEmailVerification();
        if (mounted) context.go(Routes.teenRegisterVerifyEmail);
      } else if (mounted) {
        context.go(Routes.teenRegisterComplete);
      }
    } catch (e) {
      setState(() => _error = userErrorMessage(e));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final psgcBundle = ref.watch(psgcBundleProvider);
    final authUser = ref.watch(authStateChangesProvider).value;
    final profile = ref.watch(userProfileProvider).value;
    final needsAuth = authUser == null;
    final ageLabel = _computedAgeLabel();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Teen registration'),
        leading: BackButton(onPressed: () => context.go(Routes.welcome)),
        actions: [
          if (authUser != null)
            TextButton(
              onPressed: () async {
                if (!await confirmSignOutIfPendingOperations(context, ref)) {
                  return;
                }
                await ref.read(authControllerProvider.notifier).signOut();
              },
              child: const Text('Sign out'),
            ),
        ],
      ),
      body: Column(
        children: [
          const FictionalDataBanner(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_step == 0) ...[
                    const Text(
                      'Create a demonstration Teen account to request Barangay assistance. '
                      'Registration does not verify your identity or residence.',
                    ),
                    const SizedBox(height: 24),
                    AppButton.primary(
                      label: 'Continue',
                      onPressed: () => setState(() {
                        if (authUser != null && profile == null) {
                          _step = 1;
                        } else {
                          _step = 1;
                        }
                      }),
                    ),
                  ],
                  if (_step >= 1) ...[
                    const Text(
                      'Identity and contact',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 12),
                    AppTextField(
                      controller: _fullNameController,
                      label: 'Full name',
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 12),
                    AppTextField(
                      controller: _dobController,
                      label: 'Date of birth (YYYY-MM-DD)',
                      keyboardType: TextInputType.datetime,
                      textInputAction: TextInputAction.next,
                    ),
                    if (ageLabel != null) ...[
                      const SizedBox(height: 4),
                      Text(ageLabel, style: Theme.of(context).textTheme.bodySmall),
                    ],
                    const SizedBox(height: 16),
                    const Text(
                      'Select the Barangay that should receive your assistance requests. '
                      'Geographic choices load from bundled reference data; submitting registration '
                      'requires a server connection.',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    psgcBundle.when(
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (e, _) =>
                          Text('Could not load geographic reference data.\n$e'),
                      data: (bundle) => PsgcGeoPicker(
                        bundle: bundle,
                        onChanged: (v) => setState(() => _psgcSelection = v),
                      ),
                    ),
                    const SizedBox(height: 16),
                    AppTextField(
                      controller: _contactEmailController,
                      label: 'Contact email (optional if phone provided)',
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 12),
                    AppTextField(
                      controller: _contactPhoneController,
                      label: 'Contact phone (optional if email provided)',
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Provide at least one contact method. Contact email is prefilled from '
                      'sign-in email but may differ.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 24),
                    if (needsAuth) ...[
                      const Text(
                        'Sign-in credentials',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 12),
                      AppTextField(
                        controller: _signInEmailController,
                        label: 'Sign-in email',
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 12),
                      AppTextField(
                        controller: _passwordController,
                        label: 'Password',
                        isPassword: true,
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 12),
                      AppTextField(
                        controller: _confirmPasswordController,
                        label: 'Confirm password',
                        isPassword: true,
                      ),
                    ] else ...[
                      const Text(
                        'You are signed in. Complete your Teen profile below, '
                        'or sign out to use a different account.',
                      ),
                      const SizedBox(height: 12),
                    ],
                    const SizedBox(height: 16),
                    CheckboxListTile(
                      value: _consent,
                      onChanged: (v) => setState(() => _consent = v ?? false),
                      title: Text(TeenOnboardingPolicy.privacyNoticeText),
                      controlAffinity: ListTileControlAffinity.leading,
                    ),
                    const SizedBox(height: 16),
                    AppButton.primary(
                      label: _submitting
                          ? 'Submitting…'
                          : needsAuth
                              ? 'Create account and register'
                              : 'Complete registration',
                      onPressed: _submitting ? null : _submitRegistration,
                    ),
                  ],
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _error!,
                      style: TextStyle(color: Theme.of(context).colorScheme.error),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
