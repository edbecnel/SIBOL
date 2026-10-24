import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sibol_app/features/admin/presentation/providers/admin_providers.dart';

class OrgAdminInvitationsScreen extends ConsumerStatefulWidget {
  const OrgAdminInvitationsScreen({super.key, required this.orgId});

  final String orgId;

  @override
  ConsumerState<OrgAdminInvitationsScreen> createState() =>
      _OrgAdminInvitationsScreenState();
}

class _OrgAdminInvitationsScreenState extends ConsumerState<OrgAdminInvitationsScreen> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _invitations = [];

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
      _invitations =
          await ref.read(adminApiProvider).listStaffInvitations(widget.orgId);
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _revoke(String invitationId) async {
    try {
      await ref.read(adminApiProvider).revokeInvitation(invitationId);
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
        title: const Text('Pending invitations'),
        actions: [IconButton(onPressed: _load, icon: const Icon(Icons.refresh))],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : _invitations.isEmpty
                  ? const Center(child: Text('No invitations yet.'))
                  : ListView.builder(
                      itemCount: _invitations.length,
                      itemBuilder: (context, index) {
                        final inv = _invitations[index];
                        final id = inv['invitationId'] as String? ?? '';
                        final status = inv['status'] as String? ?? '';
                        return ListTile(
                          title: Text('$status · ${inv['inviteKind']}'),
                          subtitle: Text(id),
                          trailing: status == 'pending'
                              ? TextButton(
                                  onPressed: () => _revoke(id),
                                  child: const Text('Revoke'),
                                )
                              : null,
                        );
                      },
                    ),
    );
  }
}
