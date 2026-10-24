import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sibol_app/core/constants/route_constants.dart';
import 'package:sibol_app/features/admin/presentation/providers/admin_providers.dart';
import 'package:sibol_app/features/org/domain/org_capabilities.dart';
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

  Future<void> _inviteStaff() async {
    final controller = TextEditingController();
    final email = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Invite staff'),
        content: AppTextField(
          controller: controller,
          label: 'Staff email',
          keyboardType: TextInputType.emailAddress,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Send invitation'),
          ),
        ],
      ),
    );
    if (email == null || email.isEmpty) return;
    try {
      final result = await ref.read(adminApiProvider).inviteStaffMember(
            orgId: widget.orgId,
            email: email,
            capabilities: [OrgCapabilities.caseRead],
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Invitation ${result['invitationId']} created.')),
      );
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  Future<void> _approve(String membershipId) async {
    try {
      await ref.read(adminApiProvider).approveMembership(membershipId);
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  Future<void> _suspend(String membershipId) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Suspend membership?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Suspend')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(adminApiProvider).suspendMembership(membershipId);
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Staff administration'),
        actions: [
          IconButton(
            onPressed: () => context.push(
              Routes.orgAdminInvitations(widget.orgId),
            ),
            icon: const Icon(Icons.mail_outline),
          ),
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _inviteStaff,
        child: const Icon(Icons.person_add),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : _memberships.isEmpty
                  ? const Center(child: Text('No staff memberships yet.'))
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
                                  ? TextButton(
                                      onPressed: () => _suspend(membershipId),
                                      child: const Text('Suspend'),
                                    )
                                  : null,
                        );
                      },
                    ),
    );
  }
}
