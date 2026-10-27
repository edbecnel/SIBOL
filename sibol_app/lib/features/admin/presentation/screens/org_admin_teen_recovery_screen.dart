import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sibol_app/features/admin/data/admin_api.dart';
import 'package:sibol_app/features/admin/presentation/providers/admin_providers.dart';
import 'package:sibol_app/features/admin/presentation/widgets/staff_password_reset_dialog.dart';
import 'package:sibol_app/shared/widgets/persistent_success_dialog.dart';

class OrgAdminTeenRecoveryScreen extends ConsumerStatefulWidget {
  const OrgAdminTeenRecoveryScreen({super.key, required this.orgId});

  final String orgId;

  @override
  ConsumerState<OrgAdminTeenRecoveryScreen> createState() =>
      _OrgAdminTeenRecoveryScreenState();
}

class _OrgAdminTeenRecoveryScreenState
    extends ConsumerState<OrgAdminTeenRecoveryScreen> {
  bool _loading = true;
  String? _error;
  String _organizationName = '';
  List<TeenRecoveryListEntry> _teens = [];

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
      final api = ref.read(adminApiProvider);
      if (ref.read(isCentralAdminProvider)) {
        final orgs = await api.listOrganizations();
        for (final org in orgs) {
          if (org['orgId'] == widget.orgId) {
            _organizationName = (org['name'] as String?)?.trim() ?? '';
            break;
          }
        }
      }
      final result = await api.listTeensForBarangayOrgAdminRecovery(
        managedBarangayOrgId: widget.orgId,
      );
      _organizationName = result.organizationName?.trim().isNotEmpty == true
          ? result.organizationName!.trim()
          : (_organizationName.isNotEmpty ? _organizationName : widget.orgId);
      _teens = result.teens;
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resetTeen(TeenRecoveryListEntry teen) async {
    final formResult = await showStaffPasswordResetFormDialog(
      context: context,
      displayName: teen.displayName,
      email: teen.signInEmail.isNotEmpty ? teen.signInEmail : teen.teenUid,
    );
    if (formResult == null) return;
    final password = formResult.password;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm teen account recovery'),
        content: Text(
          'Reset the sign-in password for ${teen.displayName} '
          '(${teen.signInEmail.isNotEmpty ? teen.signInEmail : teen.teenUid})?\n\n'
          'Share the temporary password privately. The teenager must change it at next sign-in.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Reset password'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await ref.read(adminApiProvider).resetTeenPasswordByBarangayOrgAdmin(
            managedBarangayOrgId: widget.orgId,
            targetTeenUid: teen.teenUid,
            newPassword: password,
          );
      if (!mounted) return;
      await showPersistentSuccessDialog(
        context,
        message:
            'The teenager\'s password has been reset. Share the temporary password privately. '
            'They must change it at next sign-in.',
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isCentral = ref.watch(isCentralAdminProvider);
    final managed = ref.watch(orgAdminManagedOrgIdsProvider);
    if (!isCentral && !managed.contains(widget.orgId)) {
      return Scaffold(
        appBar: AppBar(title: const Text('Teen account recovery')),
        body: const Center(
          child: Text(
            'You do not have permission to recover teenager accounts for this organization.',
          ),
        ),
      );
    }

    final title = _organizationName.isNotEmpty && _organizationName != widget.orgId
        ? 'Teen recovery — $_organizationName'
        : 'Teen account recovery';

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Text(
                      'Barangay organization',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    Text(
                      _organizationName,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'For account recovery only. This does not grant access to case records, '
                      'assistance requests, or other confidential information.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 16),
                    if (_teens.isEmpty)
                      const Text('No active teenager accounts are registered to this Barangay.')
                    else
                      ..._teens.map(
                        (teen) => Card(
                          child: ListTile(
                            title: Text(teen.displayName),
                            subtitle: Text(
                              teen.signInEmail.isNotEmpty
                                  ? 'Sign-in email: ${teen.signInEmail}'
                                  : 'Sign-in email unavailable',
                            ),
                            trailing: TextButton(
                              onPressed: () => _resetTeen(teen),
                              child: const Text('Reset password'),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
    );
  }
}
