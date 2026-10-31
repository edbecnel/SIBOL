import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sibol_app/features/disclosure/data/disclosure_api.dart';
import 'package:sibol_app/features/disclosure/domain/disclosure_constants.dart';
import 'package:sibol_app/features/disclosure/presentation/providers/disclosure_providers.dart';
import 'package:sibol_app/shared/widgets/app_button.dart';

class BarangayDisclosureRequestPanel extends ConsumerStatefulWidget {
  const BarangayDisclosureRequestPanel({
    super.key,
    required this.assistanceRequestId,
  });

  final String assistanceRequestId;

  @override
  ConsumerState<BarangayDisclosureRequestPanel> createState() =>
      _BarangayDisclosureRequestPanelState();
}

class _BarangayDisclosureRequestPanelState
    extends ConsumerState<BarangayDisclosureRequestPanel> {
  bool _busy = false;
  final _selectedCategories = <String>{
    DisclosureCategoryCodes.legalName,
    DisclosureCategoryCodes.contactEmail,
  };

  Future<void> _request() async {
    setState(() => _busy = true);
    try {
      await ref.read(disclosureApiProvider).requestAuthorization(
            assistanceRequestId: widget.assistanceRequestId,
            purposeCode: ReferralPurposeCodes.hospitalCoordination,
            requestedCategories: _selectedCategories.toList(),
          );
      ref.invalidate(
        disclosureAuthorizationsForAssistanceProvider(widget.assistanceRequestId),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Disclosure authorization request sent to teenager.'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auths = ref.watch(
      disclosureAuthorizationsForAssistanceProvider(widget.assistanceRequestId),
    );
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'MOPH disclosure authorization',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            const Text(
              'Request teenager authorization before sharing identifying '
              'information with the hospital. Minimum-information referrals '
              'do not require approval.',
            ),
            const SizedBox(height: 12),
            ...DisclosureCategoryCodes.all.map(
              (code) => CheckboxListTile(
                dense: true,
                value: _selectedCategories.contains(code),
                onChanged: code == DisclosureCategoryCodes.otherEssential
                    ? null
                    : (v) {
                        setState(() {
                          if (v == true) {
                            _selectedCategories.add(code);
                          } else {
                            _selectedCategories.remove(code);
                          }
                        });
                      },
                title: Text(code.replaceAll('_', ' ')),
                subtitle: code == DisclosureCategoryCodes.otherEssential
                    ? const Text('Requires legal review — not selectable in v1.')
                    : null,
              ),
            ),
            if (!DisclosureLegalPolicy.identifyingDisclosureActivated)
              const Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: Text(
                  'Identifying disclosure is not legally activated on this build. '
                  'The teenager may record a decision, but authorized hospital '
                  'referrals will be rejected by the server until legal approval.',
                  style: TextStyle(fontSize: 12),
                ),
              ),
            auths.when(
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => Text('$e'),
              data: (items) {
                if (items.isEmpty) {
                  return AppButton.primary(
                    label: 'Request authorization',
                    isLoading: _busy,
                    onPressed: _busy ? null : _request,
                  );
                }
                final latest = items.last;
                return Text('Latest authorization status: ${latest.status}');
              },
            ),
          ],
        ),
      ),
    );
  }
}
