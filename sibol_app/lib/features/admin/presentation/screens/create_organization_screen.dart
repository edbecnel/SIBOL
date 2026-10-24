import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sibol_app/features/admin/presentation/providers/admin_providers.dart';
import 'package:sibol_app/features/geo/data/nhfr_bundle.dart';
import 'package:sibol_app/features/geo/presentation/geo_providers.dart';
import 'package:sibol_app/features/geo/presentation/psgc_geo_picker.dart';
import 'package:sibol_app/shared/widgets/app_button.dart';
import 'package:sibol_app/shared/widgets/app_text_field.dart';

class CreateOrganizationScreen extends ConsumerStatefulWidget {
  const CreateOrganizationScreen({super.key});

  @override
  ConsumerState<CreateOrganizationScreen> createState() =>
      _CreateOrganizationScreenState();
}

class _CreateOrganizationScreenState extends ConsumerState<CreateOrganizationScreen> {
  final _aliasController = TextEditingController();
  final _emailController = TextEditingController();
  String _type = 'barangay';
  bool _submitting = false;
  String? _error;
  PsgcSelection? _psgcSelection;
  NhfrFacility? _selectedFacility;

  String _newIdempotencyKey() =>
      'idem-${DateTime.now().microsecondsSinceEpoch}-${Random().nextInt(1 << 31)}';

  @override
  void dispose() {
    _aliasController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() => _error = 'Initial Organization Administrator email is required.');
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      Map<String, dynamic> result;
      if (_type == 'barangay') {
        if (_psgcSelection == null) {
          throw StateError('Select a Barangay from the geographic hierarchy.');
        }
        final sel = _psgcSelection!;
        result = await ref.read(adminApiProvider).createBarangayOrganization(
              idempotencyKey: _newIdempotencyKey(),
              psgcVersion: sel.psgcVersion,
              psgcRegionCode: sel.psgcRegionCode,
              psgcProvinceCode: sel.psgcProvinceCode,
              psgcCityMunCode: sel.psgcCityMunCode,
              psgcBarangayCode: sel.psgcBarangayCode,
              initialOrgAdminEmail: email,
              displayNameAlias: _aliasController.text.trim().isEmpty
                  ? null
                  : _aliasController.text.trim(),
            );
      } else {
        if (_selectedFacility == null) {
          throw StateError('Select a hospital facility from the reference list.');
        }
        final facility = _selectedFacility!;
        final psgc = await ref.read(psgcBundleProvider.future);
        final city = psgc.node(facility.psgcCityMunCode);
        if (city == null) {
          throw StateError('Hospital location is not in the bundled reference data.');
        }
        String? provinceCode;
        if (city.cityClass != 'HUC' && city.parentCode != null) {
          final parent = psgc.node(city.parentCode!);
          if (parent != null && parent.level == 'province') {
            provinceCode = parent.code;
          }
        }
        result = await ref.read(adminApiProvider).createHospitalOrganization(
              idempotencyKey: _newIdempotencyKey(),
              nhfrSnapshotVersion: NhfrBundle.defaultVersion,
              nhfrFacilityCode: facility.nhfrFacilityCode,
              psgcVersion: psgc.version,
              psgcRegionCode: facility.psgcRegionCode,
              psgcProvinceCode: provinceCode,
              psgcCityMunCode: facility.psgcCityMunCode,
              initialOrgAdminEmail: email,
              displayNameAlias: _aliasController.text.trim().isEmpty
                  ? null
                  : _aliasController.text.trim(),
            );
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Created ${result['orgId']}. Demo invite email: ${result['demoInvitationEmail']}',
          ),
        ),
      );
      context.pop();
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final psgcAsync = ref.watch(psgcBundleProvider);
    final nhfrAsync = ref.watch(nhfrBundleProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Create organization')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DropdownButtonFormField<String>(
              value: _type,
              items: const [
                DropdownMenuItem(value: 'barangay', child: Text('Barangay')),
                DropdownMenuItem(value: 'hospital', child: Text('Hospital (MOPH)')),
              ],
              onChanged: _submitting
                  ? null
                  : (v) => setState(() {
                        _type = v ?? 'barangay';
                        _psgcSelection = null;
                        _selectedFacility = null;
                      }),
              decoration: const InputDecoration(labelText: 'Type'),
            ),
            const SizedBox(height: 12),
            if (_type == 'barangay')
              psgcAsync.when(
                loading: () => const LinearProgressIndicator(),
                error: (e, _) => Text('Could not load geographic reference data: $e'),
                data: (bundle) => Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (bundle.synthetic)
                      const Padding(
                        padding: EdgeInsets.only(bottom: 8),
                        child: Text(
                          'Using demonstration geographic reference data (offline).',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    PsgcGeoPicker(
                      bundle: bundle,
                      onChanged: (v) => setState(() => _psgcSelection = v),
                    ),
                    if (_psgcSelection != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Official identity: ${_psgcSelection!.psgcBarangayCode}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ],
                ),
              )
            else
              nhfrAsync.when(
                loading: () => const LinearProgressIndicator(),
                error: (e, _) => Text('Could not load facility reference data: $e'),
                data: (bundle) => Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (bundle.synthetic)
                      const Padding(
                        padding: EdgeInsets.only(bottom: 8),
                        child: Text(
                          'Using demonstration NHFR reference data.',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    DropdownButtonFormField<NhfrFacility>(
                      value: _selectedFacility,
                      isExpanded: true,
                      decoration: const InputDecoration(labelText: 'Hospital facility'),
                      items: bundle.facilities
                          .map(
                            (f) => DropdownMenuItem(
                              value: f,
                              child: Text('${f.facilityOfficialName} (${f.nhfrFacilityCode})'),
                            ),
                          )
                          .toList(),
                      onChanged: _submitting
                          ? null
                          : (v) => setState(() => _selectedFacility = v),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 12),
            AppTextField(
              controller: _aliasController,
              label: 'Display alias (optional)',
            ),
            const SizedBox(height: 12),
            AppTextField(
              controller: _emailController,
              label: 'Initial Organization Administrator email',
              keyboardType: TextInputType.emailAddress,
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ],
            const Spacer(),
            AppButton.primary(
              label: _submitting ? 'Creating…' : 'Create organization',
              onPressed: _submitting ? null : _submit,
            ),
          ],
        ),
      ),
    );
  }
}
