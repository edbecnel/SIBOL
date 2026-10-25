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
  String? _provinceCode;
  String? _independentCityCode;
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
    final cityMunCode = _cityMunCode ?? _independentCityCode;
    if (cityMunCode == null) {
      widget.onChanged?.call(null);
      return;
    }
    widget.onChanged?.call(
      PsgcSelection(
        psgcVersion: widget.bundle.version,
        psgcRegionCode: _regionCode!,
        psgcProvinceCode: _provinceCode,
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
    final provinces = _regionCode == null
        ? <PsgcNode>[]
        : widget.bundle.provincesUnderRegion(_regionCode!);
    final independentCities = _regionCode == null
        ? <PsgcNode>[]
        : widget.bundle.independentCitiesUnderRegion(_regionCode!);
    final citiesUnderProvince = _provinceCode == null
        ? <PsgcNode>[]
        : widget.bundle.children(_provinceCode!, 'city_mun');
    final barangaysParent = _cityMunCode ?? _independentCityCode;
    final barangays = barangaysParent == null
        ? <PsgcNode>[]
        : widget.bundle.children(barangaysParent, 'barangay');

    final usingIndependentCity = _independentCityCode != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.bundle.synthetic) ...[
          Text(
            'Demonstration geographic data only — not official PSA PSGC.',
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
          const SizedBox(height: 8),
        ],
        _dropdown(
          label: 'Region',
          value: _regionCode,
          items: regions
              .map((r) => DropdownMenuItem(value: r.code, child: Text(r.officialName)))
              .toList(),
          onChanged: (v) => setState(() {
            _regionCode = v;
            _provinceCode = null;
            _independentCityCode = null;
            _cityMunCode = null;
            _barangayCode = null;
            _emit();
          }),
        ),
        if (_regionCode != null && provinces.isNotEmpty) ...[
          const SizedBox(height: 12),
          _dropdown(
            label: 'Province',
            value: usingIndependentCity ? null : _provinceCode,
            items: provinces
                .map((p) => DropdownMenuItem(value: p.code, child: Text(p.officialName)))
                .toList(),
            onChanged: (v) => setState(() {
              _provinceCode = v;
              _independentCityCode = null;
              _cityMunCode = null;
              _barangayCode = null;
              _emit();
            }),
          ),
        ],
        if (_regionCode != null && independentCities.isNotEmpty) ...[
          const SizedBox(height: 12),
          _dropdown(
            label: 'Highly urbanized / independent city',
            value: usingIndependentCity ? _independentCityCode : null,
            hint: _provinceCode == null ? null : 'Clear province to select',
            items: independentCities
                .map((c) => DropdownMenuItem(value: c.code, child: Text(c.officialName)))
                .toList(),
            onChanged: _provinceCode == null
                ? (v) => setState(() {
                    _independentCityCode = v;
                    _provinceCode = null;
                    _cityMunCode = null;
                    _barangayCode = null;
                    _emit();
                  })
                : null,
          ),
        ],
        if (_provinceCode != null && citiesUnderProvince.isNotEmpty) ...[
          const SizedBox(height: 12),
          _dropdown(
            label: 'City / municipality',
            value: _cityMunCode,
            items: citiesUnderProvince
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
          _dropdown(
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

  Widget _dropdown({
    required String label,
    required String? value,
    required List<DropdownMenuItem<String>> items,
    required ValueChanged<String?>? onChanged,
    String? hint,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        helperText: hint,
      ),
      items: items,
      onChanged: onChanged,
    );
  }
}
