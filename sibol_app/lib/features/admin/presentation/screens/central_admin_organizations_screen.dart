import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sibol_app/core/constants/route_constants.dart';
import 'package:sibol_app/features/admin/presentation/providers/admin_providers.dart';
import 'package:sibol_app/shared/widgets/app_button.dart';

class CentralAdminOrganizationsScreen extends ConsumerStatefulWidget {
  const CentralAdminOrganizationsScreen({super.key});

  @override
  ConsumerState<CentralAdminOrganizationsScreen> createState() =>
      _CentralAdminOrganizationsScreenState();
}

class _CentralAdminOrganizationsScreenState
    extends ConsumerState<CentralAdminOrganizationsScreen> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _orgs = [];

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
      _orgs = await api.listOrganizations();
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Organizations'),
        actions: [
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push(Routes.centralAdminCreateOrganization),
        child: const Icon(Icons.add),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : _orgs.isEmpty
                  ? const Center(child: Text('No organizations yet.'))
                  : ListView.builder(
                      itemCount: _orgs.length,
                      itemBuilder: (context, index) {
                        final org = _orgs[index];
                        final orgId = org['orgId'] as String? ?? '';
                        return ListTile(
                          title: Text(org['name'] as String? ?? orgId),
                          subtitle: Text(
                            '${org['type']} · ${org['status']}',
                          ),
                          onTap: () => context.push(
                            Routes.centralAdminOrganizationDetail(orgId),
                          ),
                        );
                      },
                    ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: OutlinedButton(
          onPressed: () async {
            try {
              await ref.read(adminApiProvider).bootstrapCentralAdminForEmulator();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Central Admin flag set for current user.'),
                  ),
                );
              }
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(e.toString())),
                );
              }
            }
          },
          child: const Text('Emulator: bootstrap Central Admin'),
        ),
      ),
    );
  }
}
