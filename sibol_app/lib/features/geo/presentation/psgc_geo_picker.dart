import 'package:flutter/material.dart';
import 'package:sibol_app/features/geo/data/psgc_bundle.dart';

class PsgcSelection {
  const PsgcSelection({
    required this.psgcVersion,
    required this.psgcRegionCode,
    required this.psgcProvinceCode,
    required this.psgcCityMunCode,
    required this.psgcBarangayCode,
    required this.barangayName,
    required this.subtitle,
  });

  final String psgcVersion;
  final String psgcRegionCode;
  final String? psgcProvinceCode;
  final String psgcCityMunCode;
  final String psgcBarangayCode;
  final String barangayName;
  final String subtitle;
}

class PsgcGeoPicker extends StatefulWidget {
  const PsgcGeoPicker({
    super.key,
    required this.bundle,
    this.onChanged,
  });

  final PsgcBundle bundle;
  final ValueChanged<PsgcSelection?>? onChanged;

  @override
  State<PsgcGeoPicker> createState() => _PsgcGeoPickerState();
}

class _PsgcGeoPickerState extends State<PsgcGeoPicker> {
  String? _regionCode;
  String? _lguParentCode;
  String? _cityMunCode;
  String? _barangayCode;

  void _emit() {
    if (_regionCode == null || _barangayCode == null) {
      widget.onChanged?.call(null);
      return;
    }
    final barangay = widget.bundle.node(_barangayCode!);
    if (barangay == null) {
      widget.onChanged?.call(null);
      return;
    }
    final lgu = _lguParentCode != null ? widget.bundle.node(_lguParentCode!) : null;
    final provinceCode = lgu?.level == 'province' ? lgu!.code : null;
    final cityMunCode = _cityMunCode ?? (lgu?.level == 'city_mun' ? lgu!.code : null);
    if (cityMunCode == null) {
      widget.onChanged?.call(null);
      return;
    }
    widget.onChanged?.call(
      PsgcSelection(
        psgcVersion: widget.bundle.version,
        psgcRegionCode: _regionCode!,
        psgcProvinceCode: provinceCode,
        psgcCityMunCode: cityMunCode,
        psgcBarangayCode: _barangayCode!,
        barangayName: barangay.officialName,
        subtitle: widget.bundle.geographicSubtitle(barangay),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final regions = widget.bundle.regions();
    final lguParents =
        _regionCode == null ? <PsgcNode>[] : widget.bundle.lguParentsUnderRegion(_regionCode!);
    final lgu = _lguParentCode != null ? widget.bundle.node(_lguParentCode!) : null;
    final cities = lgu?.level == 'province'
        ? widget.bundle.children(lgu!.code, 'city_mun')
        : <PsgcNode>[];
    final barangaysParent = _cityMunCode ?? (lgu?.level == 'city_mun' ? lgu!.code : null);
    final barangays = barangaysParent == null
        ? <PsgcNode>[]
        : widget.bundle.children(barangaysParent, 'barangay');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _searchableDropdown(
          label: 'Region',
          value: _regionCode,
          items: regions
              .map((r) => DropdownMenuItem(value: r.code, child: Text(r.officialName)))
              .toList(),
          onChanged: (v) => setState(() {
            _regionCode = v;
            _lguParentCode = null;
            _cityMunCode = null;
            _barangayCode = null;
            _emit();
          }),
        ),
        if (_regionCode != null) ...[
          const SizedBox(height: 12),
          _searchableDropdown(
            label: 'Province or city',
            value: _lguParentCode,
            items: lguParents
                .map(
                  (p) => DropdownMenuItem(
                    value: p.code,
                    child: Text(
                      p.level == 'province'
                          ? '${p.officialName} (Province)'
                          : '${p.officialName} (City)',
                    ),
                  ),
                )
                .toList(),
            onChanged: (v) => setState(() {
              _lguParentCode = v;
              _cityMunCode = null;
              _barangayCode = null;
              _emit();
            }),
          ),
        ],
        if (lgu?.level == 'province') ...[
          const SizedBox(height: 12),
          _searchableDropdown(
            label: 'Municipality / city',
            value: _cityMunCode,
            items: cities
                .map((c) => DropdownMenuItem(value: c.code, child: Text(c.officialName)))
                .toList(),
            onChanged: (v) => setState(() {
              _cityMunCode = v;
              _barangayCode = null;
              _emit();
            }),
          ),
        ],
        if (barangays.isNotEmpty) ...[
          const SizedBox(height: 12),
          _searchableDropdown(
            label: 'Barangay',
            value: _barangayCode,
            items: barangays
                .map(
                  (b) => DropdownMenuItem(
                    value: b.code,
                    child: Text('${b.officialName} — ${widget.bundle.geographicSubtitle(b)}'),
                  ),
                )
                .toList(),
            onChanged: (v) => setState(() {
              _barangayCode = v;
              _emit();
            }),
          ),
        ],
      ],
    );
  }

  Widget _searchableDropdown({
    required String label,
    required String? value,
    required List<DropdownMenuItem<String>> items,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      isExpanded: true,
      decoration: InputDecoration(labelText: label),
      items: items,
      onChanged: onChanged,
    );
  }
}
