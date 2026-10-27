import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sibol_app/core/constants/route_constants.dart';
import 'package:sibol_app/features/admin/presentation/providers/admin_providers.dart';
import 'package:sibol_app/shared/widgets/app_text_field.dart';

class CentralAdminOrgDetailScreen extends ConsumerStatefulWidget {
  const CentralAdminOrgDetailScreen({super.key, required this.orgId});

  final String orgId;

  @override
  ConsumerState<CentralAdminOrgDetailScreen> createState() =>
      _CentralAdminOrgDetailScreenState();
}

class _CentralAdminOrgDetailScreenState
    extends ConsumerState<CentralAdminOrgDetailScreen> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _memberships = [];
  String _status = 'active';
  String _organizationName = '';

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
      final orgs = await api.listOrganizations();
      for (final org in orgs) {
        if (org['orgId'] == widget.orgId) {
          _organizationName = (org['name'] as String?)?.trim() ?? '';
          _status = (org['status'] as String?) ?? _status;
          break;
        }
      }
      if (_organizationName.isEmpty) {
        _organizationName = widget.orgId;
      }
      final directory = await api.listMemberships(widget.orgId);
      _memberships = directory.memberships;
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _appointAdmin() async {
    final controller = TextEditingController();
    final email = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Appoint Organization Administrator'),
        content: AppTextField(
          controller: controller,
          label: 'Email',
          keyboardType: TextInputType.emailAddress,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Invite'),
          ),
        ],
      ),
    );
    if (email == null || email.isEmpty) return;
    try {
      final result = await ref.read(adminApiProvider).appointOrganizationAdmin(
            orgId: widget.orgId,
            email: email,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Invitation ${result['invitationId']} created.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  Future<void> _toggleStatus() async {
    final next = _status == 'active' ? 'suspended' : 'active';
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Set status to $next?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Confirm')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(adminApiProvider).setOrganizationStatus(
            orgId: widget.orgId,
            status: next,
          );
      setState(() => _status = next);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_organizationName)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    OutlinedButton(
                      onPressed: _appointAdmin,
                      child: const Text('Appoint backup Organization Administrator'),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton(
                      onPressed: _toggleStatus,
                      child: Text('Toggle organization status ($_status)'),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton(
                      onPressed: () => context.push(
                        Routes.orgAdminStaff(widget.orgId),
                      ),
                      child: const Text('Manage staff'),
                    ),
                    const SizedBox(height: 24),
                    const Text('Memberships', style: TextStyle(fontWeight: FontWeight.bold)),
                    if (_memberships.isEmpty)
                      const Text('No memberships yet.')
                    else
                      ..._memberships.map(
                        (m) => ListTile(
                          title: Text(m['accountUid'] as String? ?? '—'),
                          subtitle: Text(
                            '${m['status']} · ${(m['capabilities'] as List?)?.join(', ') ?? ''}',
                          ),
                        ),
                      ),
                  ],
                ),
    );
  }
}
