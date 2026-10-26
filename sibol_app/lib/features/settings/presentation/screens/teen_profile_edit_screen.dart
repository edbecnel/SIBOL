import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sibol_app/core/providers/firebase_providers.dart';
import 'package:sibol_app/features/auth/domain/teen_profile_validation.dart';
import 'package:sibol_app/features/auth/presentation/providers/auth_providers.dart';
import 'package:sibol_app/shared/widgets/app_button.dart';
import 'package:sibol_app/shared/widgets/app_text_field.dart';

class TeenProfileEditScreen extends ConsumerStatefulWidget {
  const TeenProfileEditScreen({super.key});

  @override
  ConsumerState<TeenProfileEditScreen> createState() =>
      _TeenProfileEditScreenState();
}

class _TeenProfileEditScreenState extends ConsumerState<TeenProfileEditScreen> {
  final _nameController = TextEditingController();
  final _dobController = TextEditingController();
  final _barangayController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _parentController = TextEditingController();
  final _authEmailController = TextEditingController();
  String? _error;
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _dobController.dispose();
    _barangayController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _parentController.dispose();
    _authEmailController.dispose();
    super.dispose();
  }

  void _populateFromProfile() {
    final profile = ref.read(userProfileProvider).value;
    final authEmail = ref.read(authStateChangesProvider).value?.email;
    if (profile == null) return;
    _nameController.text = profile.displayName;
    _dobController.text = profile.dateOfBirth ?? '';
    _barangayController.text = profile.assignedBarangay ?? '';
    _emailController.text = profile.contactEmail ?? '';
    _phoneController.text = profile.contactPhone ?? '';
    _parentController.text = profile.parentGuardianContact ?? '';
    _authEmailController.text = authEmail ?? '';
  }

  Future<void> _saveProfile() async {
    final profile = ref.read(userProfileProvider).value;
    final uid = ref.read(authStateChangesProvider).value?.uid;
    if (profile == null || uid == null) return;

    final validation = TeenProfileValidation.validateProfile(
      displayName: _nameController.text,
      dateOfBirth: _dobController.text,
      contactEmail: _emailController.text,
      contactPhone: _phoneController.text,
      barangay: _barangayController.text,
    );
    if (validation != null) {
      setState(() => _error = validation);
      return;
    }

    setState(() {
      _error = null;
      _saving = true;
    });
    try {
      await ref.read(userProfileRepositoryProvider).updateTeenSelfProfile(
            uid: uid,
            displayName: _nameController.text.trim(),
            assignedBarangay: _barangayController.text.trim(),
            dateOfBirth: _dobController.text.trim(),
            contactEmail: _emailController.text.trim(),
            contactPhone: _phoneController.text.trim(),
            parentGuardianContact: _parentController.text.trim(),
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated.')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _updateAuthEmail() async {
    final user = FirebaseAuth.instance.currentUser;
    final newEmail = _authEmailController.text.trim();
    if (user == null || newEmail.isEmpty) return;
    setState(() {
      _error = null;
      _saving = true;
    });
    try {
      await user.verifyBeforeUpdateEmail(newEmail);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Verification email sent. Sign-in email updates after you confirm.',
            ),
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      setState(() => _error = e.message ?? 'Could not start email change.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(userProfileProvider).value;
    if (profile != null && _nameController.text.isEmpty) {
      _populateFromProfile();
    }
    return Scaffold(
      appBar: AppBar(title: const Text('My profile')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Profile contact email is separate from your sign-in email.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          AppTextField(controller: _nameController, label: 'Full name'),
          const SizedBox(height: 12),
          AppTextField(
            controller: _dobController,
            label: 'Date of birth (YYYY-MM-DD)',
          ),
          const SizedBox(height: 12),
          AppTextField(controller: _barangayController, label: 'Barangay'),
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
            'Keep at least one valid contact method (email or phone).',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          AppTextField(
            controller: _parentController,
            label: 'Parent/guardian contact (optional)',
          ),
          const SizedBox(height: 24),
          AppButton.primary(
            label: 'Save profile',
            isLoading: _saving,
            onPressed: _saving ? null : _saveProfile,
          ),
          const Divider(height: 32),
          Text(
            'Sign-in email (Firebase Authentication)',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          AppTextField(
            controller: _authEmailController,
            label: 'New sign-in email',
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 8),
          AppButton.primary(
            label: 'Send verification for sign-in email change',
            isLoading: _saving,
            onPressed: _saving ? null : _updateAuthEmail,
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
        ],
      ),
    );
  }
}
