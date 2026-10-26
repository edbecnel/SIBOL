import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sibol_app/features/admin/domain/org_staff_capability_options.dart';
import 'package:sibol_app/features/admin/presentation/providers/admin_providers.dart';
import 'package:sibol_app/features/org/domain/entities/organization.dart';
import 'package:sibol_app/features/org/presentation/providers/organization_directory_providers.dart';
import 'package:sibol_app/shared/widgets/app_button.dart';
import 'package:sibol_app/shared/widgets/app_text_field.dart';

class OrgAdminStaffScreen extends ConsumerStatefulWidget {
  const OrgAdminStaffScreen({super.key, required this.orgId});

  final String orgId;

  @override
  ConsumerState<OrgAdminStaffScreen> createState() => _OrgAdminStaffScreenState();
}

class _OrgAdminStaffScreenState extends ConsumerState<OrgAdminStaffScreen> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _memberships = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      _memberships =
          await ref.read(adminApiProvider).listMemberships(widget.orgId);
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  OrganizationType _orgTypeFromDirectory() {
    final entry = ref.read(organizationDirectoryEntryProvider(widget.orgId)).value;
    return entry?.type ?? OrganizationType.barangay;
  }

  Future<void> _addStaffMember() async {
    final orgType = _orgTypeFromDirectory();
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    final allowed = OrgStaffCapabilityOptions.capabilitiesFor(orgType);
    final selected = Set<String>.from(
      OrgStaffCapabilityOptions.defaultSelection(orgType),
    );

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setLocal) => AlertDialog(
          title: const Text('Add staff member'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppTextField(
                  controller: nameController,
                  label: 'Display name',
                ),
                const SizedBox(height: 8),
                AppTextField(
                  controller: emailController,
                  label: 'Email identifier',
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 8),
                AppTextField(
                  controller: passwordController,
                  label: 'Initial password',
                  isPassword: true,
                ),
                const SizedBox(height: 12),
                const Text('Operational capabilities'),
                ...allowed.map(
                  (cap) => CheckboxListTile(
                    value: selected.contains(cap),
                    onChanged: (v) {
                      setLocal(() {
                        if (v == true) {
                          selected.add(cap);
                        } else {
                          selected.remove(cap);
                        }
                      });
                    },
                    title: Text(cap, style: const TextStyle(fontSize: 13)),
                    dense: true,
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Create account'),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true) return;

    final displayName = nameController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text;
    if (displayName.length < 2) {
      _showMessage('Display name must be at least 2 characters.');
      return;
    }
    if (email.isEmpty) {
      _showMessage('Email identifier is required.');
      return;
    }
    if (password.length < 8) {
      _showMessage('Initial password must be at least 8 characters.');
      return;
    }
    if (selected.isEmpty) {
      _showMessage('Select at least one capability.');
      return;
    }

    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm staff account'),
        content: Text(
          'Create account for $displayName ($email) with '
          '${selected.length} capability(ies)?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    try {
      final clientOperationId =
          'provision-${DateTime.now().microsecondsSinceEpoch}';
      final result = await ref.read(adminApiProvider).provisionStaffMember(
            orgId: widget.orgId,
            email: email,
            displayName: displayName,
            password: password,
            capabilities: selected.toList(),
            clientOperationId: clientOperationId,
          );
      if (!mounted) return;
      final replay = result['idempotentReplay'] == true;
      _showMessage(
        replay
            ? 'Staff account already exists for this request.'
            : 'Staff account created. They can sign in with the assigned credentials.',
      );
      await _load();
    } catch (e) {
      if (!mounted) return;
      _showMessage('$e');
    }
  }

  void _showMessage(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _approve(String membershipId) async {
    try {
      await ref.read(adminApiProvider).approveMembership(membershipId);
      await _load();
    } catch (e) {
      if (!mounted) return;
      _showMessage('$e');
    }
  }

  Future<void> _editCapabilities(Map<String, dynamic> membership) async {
    final orgType = _orgTypeFromDirectory();
    final membershipId = membership['membershipId'] as String? ?? '';
    final current = (membership['capabilities'] as List?)?.cast<String>() ?? [];
    final allowed = OrgStaffCapabilityOptions.capabilitiesFor(orgType);
    final selected = current.where(allowed.contains).toSet();

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setLocal) => AlertDialog(
          title: const Text('Staff capabilities'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: allowed
                  .map(
                    (cap) => CheckboxListTile(
                      value: selected.contains(cap),
                      onChanged: (v) {
                        setLocal(() {
                          if (v == true) {
                            selected.add(cap);
                          } else {
                            selected.remove(cap);
                          }
                        });
                      },
                      title: Text(cap),
                    ),
                  )
                  .toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
    if (saved != true) return;
    if (selected.isEmpty) {
      _showMessage('Select at least one capability.');
      return;
    }
    try {
      await ref.read(adminApiProvider).updateMembershipCapabilities(
            membershipId: membershipId,
            capabilities: selected.toList(),
          );
      await _load();
    } catch (e) {
      if (!mounted) return;
      _showMessage('$e');
    }
  }

  Future<void> _suspend(String membershipId) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Suspend membership?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Suspend'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(adminApiProvider).suspendMembership(membershipId);
      await _load();
    } catch (e) {
      if (!mounted) return;
      _showMessage('$e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final managed = ref.watch(orgAdminManagedOrgIdsProvider);
    if (!managed.contains(widget.orgId)) {
      return Scaffold(
        appBar: AppBar(title: const Text('Staff management')),
        body: const Center(
          child: Text('You do not have permission to manage staff for this organization.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Staff management'),
        actions: [
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addStaffMember,
        icon: const Icon(Icons.person_add),
        label: const Text('Add staff'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : _memberships.isEmpty
                  ? const Center(
                      child: Text('No staff memberships yet. Use Add staff to create an account.'),
                    )
                  : ListView.builder(
                      itemCount: _memberships.length,
                      itemBuilder: (context, index) {
                        final m = _memberships[index];
                        final membershipId = m['membershipId'] as String? ?? '';
                        final status = m['status'] as String? ?? '';
                        return ListTile(
                          title: Text(m['accountUid'] as String? ?? '—'),
                          subtitle: Text(
                            '$status · ${(m['capabilities'] as List?)?.join(', ') ?? ''}',
                          ),
                          trailing: status == 'pending'
                              ? TextButton(
                                  onPressed: () => _approve(membershipId),
                                  child: const Text('Approve'),
                                )
                              : status == 'active'
                                  ? Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        TextButton(
                                          onPressed: () => _editCapabilities(m),
                                          child: const Text('Caps'),
                                        ),
                                        TextButton(
                                          onPressed: () => _suspend(membershipId),
                                          child: const Text('Suspend'),
                                        ),
                                      ],
                                    )
                                  : status == 'suspended'
                                      ? TextButton(
                                          onPressed: () async {
                                            try {
                                              await ref
                                                  .read(adminApiProvider)
                                                  .reactivateMembership(membershipId);
                                              await _load();
                                            } catch (e) {
                                              if (!context.mounted) return;
                                              _showMessage('$e');
                                            }
                                          },
                                          child: const Text('Reactivate'),
                                        )
                                      : null,
                        );
                      },
                    ),
    );
  }
}
