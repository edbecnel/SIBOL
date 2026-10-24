import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sibol_app/core/constants/route_constants.dart';
import 'package:sibol_app/core/errors/failure.dart';
import 'package:sibol_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:sibol_app/features/geo/presentation/geo_providers.dart';
import 'package:sibol_app/features/geo/presentation/psgc_geo_picker.dart';
import 'package:sibol_app/features/teen_registration/domain/teen_onboarding_policy.dart';
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
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _displayNameController = TextEditingController();
  bool _consent = false;
  PsgcSelection? _psgcSelection;
  bool _submitting = false;
  String? _error;
  bool _authCreated = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _displayNameController.dispose();
    super.dispose();
  }

  String? _validateCredentials() {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      return 'Enter a valid email address.';
    }
    if (_passwordController.text.length < 8) {
      return 'Password must be at least 8 characters.';
    }
    if (_passwordController.text != _confirmPasswordController.text) {
      return 'Passwords do not match.';
    }
    return null;
  }

  Future<void> _createAuthAccount() async {
    final validation = _validateCredentials();
    if (validation != null) {
      setState(() => _error = validation);
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await ref.read(authControllerProvider.notifier).registerWithEmail(
            _emailController.text.trim(),
            _passwordController.text,
          );
      _authCreated = true;
      setState(() => _step = 2);
    } catch (e) {
      setState(() => _error = e is Failure ? e.message : e.toString());
    } finally {
      setState(() => _submitting = false);
    }
  }

  Future<void> _submitProfile() async {
    if (_psgcSelection == null) {
      setState(() => _error = 'Select a Barangay for assistance routing.');
      return;
    }
    if (!_consent) {
      setState(() => _error = 'Acknowledge the privacy notice to continue.');
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final sel = _psgcSelection!;
      await ref.read(teenRegistrationApiProvider).registerTeenAccount(
            selectedBarangayPsgcCode: sel.psgcBarangayCode,
            psgcVersion: sel.psgcVersion,
            psgcRegionCode: sel.psgcRegionCode,
            psgcProvinceCode: sel.psgcProvinceCode,
            psgcCityMunCode: sel.psgcCityMunCode,
            displayName: _displayNameController.text.trim(),
            privacyConsentAcknowledged: true,
          );
      if (TeenOnboardingPolicy.requireEmailVerificationBeforeAssistance) {
        await ref.read(authControllerProvider.notifier).sendEmailVerification();
        if (mounted) context.go(Routes.teenRegisterVerifyEmail);
      } else {
        try {
          await ref.read(authControllerProvider.notifier).sendEmailVerification();
        } catch (_) {}
        if (mounted) context.go(Routes.teenRegisterComplete);
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final psgcBundle = ref.watch(psgcBundleProvider);
    final authUser = ref.watch(authStateChangesProvider).value;
    final profile = ref.watch(userProfileProvider).value;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Teen registration'),
        leading: BackButton(onPressed: () => context.go(Routes.welcome)),
        actions: [
          if (authUser != null)
            TextButton(
              onPressed: () => ref.read(authControllerProvider.notifier).signOut(),
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
                          _step = 2;
                        } else {
                          _step = 1;
                        }
                      }),
                    ),
                  ],
                  if (_step == 1 && authUser == null) ...[
                    AppTextField(
                      controller: _emailController,
                      label: 'Email',
                      keyboardType: TextInputType.emailAddress,
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
                    const SizedBox(height: 16),
                    AppButton.primary(
                      label: _submitting ? 'Creating account…' : 'Create sign-in',
                      onPressed: _submitting ? null : _createAuthAccount,
                    ),
                  ],
                  if (_step == 1 && authUser != null && profile == null && !_authCreated) ...[
                    const Text(
                      'You are already signed in. Continue to complete your Teen profile, '
                      'or sign out to use a different account.',
                    ),
                    const SizedBox(height: 16),
                    AppButton.primary(
                      label: 'Continue profile setup',
                      onPressed: () => setState(() => _step = 2),
                    ),
                  ],
                  if (_step >= 2) ...[
                    AppTextField(
                      controller: _displayNameController,
                      label: 'Display name (optional)',
                    ),
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
                      error: (e, _) => Text('Could not load geographic reference data.\n$e'),
                      data: (bundle) => PsgcGeoPicker(
                        bundle: bundle,
                        onChanged: (v) => setState(() => _psgcSelection = v),
                      ),
                    ),
                    const SizedBox(height: 16),
                    CheckboxListTile(
                      value: _consent,
                      onChanged: (v) => setState(() => _consent = v ?? false),
                      title: Text(TeenOnboardingPolicy.privacyNoticeText),
                      controlAffinity: ListTileControlAffinity.leading,
                    ),
                    const SizedBox(height: 16),
                    AppButton.primary(
                      label: _submitting ? 'Submitting…' : 'Complete registration',
                      onPressed: _submitting ? null : _submitProfile,
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
