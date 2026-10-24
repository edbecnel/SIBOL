import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sibol_app/features/admin/presentation/providers/admin_providers.dart';

class MyInvitationsScreen extends ConsumerStatefulWidget {
  const MyInvitationsScreen({super.key});

  @override
  ConsumerState<MyInvitationsScreen> createState() => _MyInvitationsScreenState();
}

class _MyInvitationsScreenState extends ConsumerState<MyInvitationsScreen> {
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
      _invitations = await ref.read(adminApiProvider).listMyPendingInvitations();
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _accept(String invitationId) async {
    try {
      final result = await ref.read(adminApiProvider).acceptInvitation(invitationId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Membership ${result['membershipId']} → ${result['status']}')),
      );
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
        title: const Text('Your invitations'),
        actions: [IconButton(onPressed: _load, icon: const Icon(Icons.refresh))],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : _invitations.isEmpty
                  ? const Center(child: Text('No pending invitations.'))
                  : ListView.builder(
                      itemCount: _invitations.length,
                      itemBuilder: (context, index) {
                        final inv = _invitations[index];
                        final id = inv['invitationId'] as String? ?? '';
                        return ListTile(
                          title: Text(inv['orgName'] as String? ?? inv['orgId'] as String? ?? ''),
                          subtitle: Text('${inv['inviteKind']} · $id'),
                          trailing: TextButton(
                            onPressed: () => _accept(id),
                            child: const Text('Accept'),
                          ),
                        );
                      },
                    ),
    );
  }
}
