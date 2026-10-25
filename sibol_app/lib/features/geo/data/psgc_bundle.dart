import 'dart:convert';

import 'package:flutter/services.dart';

class PsgcNode {
  PsgcNode({
    required this.code,
    required this.level,
    required this.officialName,
    required this.parentCode,
    this.cityClass,
  });

  final String code;
  final String level;
  final String officialName;
  final String? parentCode;
  final String? cityClass;

  factory PsgcNode.fromJson(Map<String, dynamic> json) {
    return PsgcNode(
      code: json['code'] as String,
      level: json['level'] as String,
      officialName: json['officialName'] as String,
      parentCode: json['parentCode'] as String?,
      cityClass: json['cityClass'] as String?,
    );
  }
}

class PsgcBundle {
  PsgcBundle({required this.version, required this.nodes, this.synthetic = false});

  final String version;
  final List<PsgcNode> nodes;
  final bool synthetic;

  static const defaultVersion = 'psgc-psa-2025-2q';

  static Future<PsgcBundle> load({String version = defaultVersion}) async {
    final raw = await rootBundle.loadString('assets/geo/$version.json');
    final map = jsonDecode(raw) as Map<String, dynamic>;
    final list = (map['nodes'] as List<dynamic>)
        .map((e) => PsgcNode.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
    return PsgcBundle(
      version: map['version'] as String,
      nodes: list,
      synthetic: map['synthetic'] == true,
    );
  }

  PsgcNode? node(String code) {
    for (final n in nodes) {
      if (n.code == code) return n;
    }
    return null;
  }

  List<PsgcNode> regions() =>
      nodes.where((n) => n.level == 'region').toList()
        ..sort((a, b) => a.officialName.compareTo(b.officialName));

  List<PsgcNode> provincesUnderRegion(String regionCode) {
    return nodes
        .where((n) => n.parentCode == regionCode && n.level == 'province')
        .toList()
      ..sort((a, b) => a.officialName.compareTo(b.officialName));
  }

  List<PsgcNode> independentCitiesUnderRegion(String regionCode) {
    return nodes
        .where(
          (n) =>
              n.parentCode == regionCode &&
              n.level == 'city_mun' &&
              (n.cityClass == 'HUC' || n.cityClass == 'ICC'),
        )
        .toList()
      ..sort((a, b) => a.officialName.compareTo(b.officialName));
  }

  /// @deprecated Use [provincesUnderRegion] and [independentCitiesUnderRegion].
  List<PsgcNode> lguParentsUnderRegion(String regionCode) {
    final out = <PsgcNode>[...provincesUnderRegion(regionCode), ...independentCitiesUnderRegion(regionCode)];
    return out;
  }

  List<PsgcNode> children(String parentCode, String level) {
    return nodes
        .where((n) => n.parentCode == parentCode && n.level == level)
        .toList()
      ..sort((a, b) => a.officialName.compareTo(b.officialName));
  }

  String geographicSubtitle(PsgcNode barangay) {
    final parts = <String>[];
    PsgcNode? current = barangay;
    while (current?.parentCode != null) {
      final parent = node(current!.parentCode!);
      if (parent == null) break;
      if (parent.level == 'city_mun' || parent.level == 'province') {
        parts.add(parent.officialName);
      }
      current = parent;
    }
    return parts.join(', ');
  }
}
